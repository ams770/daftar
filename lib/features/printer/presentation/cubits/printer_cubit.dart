import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/printer/thermal_printer_service.dart';
import '../../../../core/services/pdf/invoice_pdf_service.dart';
import '../../../../core/services/pdf/pdf_to_image_service.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../invoices/domain/entities/money_collection.dart';
import '../../../../core/services/settings_service.dart';
import 'package:flutter/services.dart';
import './printer_state.dart';

class PrinterCubit extends Cubit<PrinterState> {
  final ThermalPrinterService _service;
  final SettingsService _settingsService;
  StreamSubscription<PrinterConnectionState>? _stateSub;
  Timer? _watchdogTimer;

  static const String _keyPrinterAddress = 'pref_printer_address';
  static const String _keyPrinterName = 'pref_printer_name';
  static const String _keyPrinterWidth = 'pref_printer_width';

  String? _connectedName;
  String? _connectedAddr;
  PrinterWidth _currentWidth = PrinterWidth.inch3; // Default to 3 inch for this app
  PrinterWidth get currentWidth => _currentWidth;
  List<BluetoothPrinterDevice> _cachedDevices = [];

  PrinterCubit(this._service, this._settingsService) : super(PrinterInitial()) {
    _listenToNative();
    _loadAndAutoConnect();
  }

  void _startWatchdog() {
    _stopWatchdog();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (state is PrinterConnected) {
        final alive = await _service.pingPrinter();
        if (!alive && state is PrinterConnected) {
          emit(PrinterDisconnected(devices: _devices));
          _stopWatchdog();
        }
      }
    });
  }

  void _stopWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  List<BluetoothPrinterDevice> get _devices => List.unmodifiable(_cachedDevices);
  bool get isConnected => state is PrinterConnected;

  Future<void> _loadAndAutoConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddr = prefs.getString(_keyPrinterAddress);
    final savedName = prefs.getString(_keyPrinterName);
    final savedWidth = prefs.getString(_keyPrinterWidth);

    if (savedWidth != null) {
      _currentWidth = PrinterWidth.values.firstWhere(
        (e) => e.name == savedWidth,
        orElse: () => PrinterWidth.inch3,
      );
    }

    if (savedAddr != null) {
      _connectedAddr = savedAddr;
      _connectedName = savedName;

      emit(PrinterSearching(address: savedAddr, name: savedName, devices: _devices));

      try {
        await _service.connect(savedAddr);
        await _service.configurePaperWidth(_currentWidth);
      } catch (e) {
        emit(PrinterDisconnected(devices: _devices));
      }
    }
  }

  Future<void> _savePrinter(String address, String? name, PrinterWidth width) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrinterAddress, address);
    await prefs.setString(_keyPrinterWidth, width.name);
    if (name != null) {
      await prefs.setString(_keyPrinterName, name);
    }
  }

  Future<void> _clearSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrinterAddress);
    await prefs.remove(_keyPrinterName);
    await prefs.remove(_keyPrinterWidth);
    _connectedAddr = null;
    _connectedName = null;
    _currentWidth = PrinterWidth.inch3;
  }

  void _listenToNative() {
    _stateSub = _service.connectionStateStream.listen((nativeState) {
      switch (nativeState) {
        case PrinterConnectionState.connected:
          if (_connectedAddr != null) {
            emit(PrinterConnected(
              deviceName: _connectedName,
              address: _connectedAddr,
              width: _currentWidth,
              devices: _devices,
            ));
            _savePrinter(_connectedAddr!, _connectedName, _currentWidth);
            _service.configurePaperWidth(_currentWidth);
            _startWatchdog();
          } else {
            emit(PrinterDisconnected(devices: _devices));
          }
          break;
        case PrinterConnectionState.connecting:
          _stopWatchdog();
          emit(PrinterConnecting(_connectedAddr ?? '...', deviceName: _connectedName, devices: _devices));
          break;
        case PrinterConnectionState.disconnected:
          _stopWatchdog();
          emit(PrinterDisconnected(devices: _devices));
          break;
        case PrinterConnectionState.bluetoothOff:
          _stopWatchdog();
          emit(PrinterBluetoothOff(devices: _devices));
          break;
        case PrinterConnectionState.error:
          _stopWatchdog();
          emit(PrinterError('Connection error', devices: _devices));
          break;
      }
    });
  }

  Future<void> scanDevices() async {
    final isBTEnabled = await _service.isBluetoothEnabled();
    if (!isBTEnabled) {
      emit(PrinterBluetoothOff(devices: _devices));
      return;
    }

    emit(PrinterScanning(devices: _devices));
    try {
      final devices = await _service.scanDevices();
      _cachedDevices = devices;
      emit(PrinterScanned(devices));
    } catch (e) {
      emit(PrinterError(e.toString(), devices: _devices));
    }
  }

  Future<void> connect(BluetoothPrinterDevice device, PrinterWidth width) async {
    _connectedName = device.name;
    _connectedAddr = device.address;
    _currentWidth = width;
    emit(PrinterConnecting(device.address, width: width, devices: _devices));
    try {
      await _service.connect(device.address);
      await _service.configurePaperWidth(width);
    } catch (e) {
      emit(PrinterError(e.toString(), devices: _devices));
    }
  }

  Future<void> disconnect() async {
    _stopWatchdog();
    _connectedName = null;
    _connectedAddr = null;
    await _clearSavedPrinter();
    await _service.disconnect();
    emit(PrinterDisconnected(devices: _devices));
  }

  Future<void> printInvoice(Invoice invoice) async {
    if (state is PrinterConnected) {
      final alive = await _service.pingPrinter();
      if (!alive) await Future.delayed(Duration.zero);
    }

    if (state is! PrinterConnected) {
      final actualState = await _service.getConnectionState();
      if (actualState != PrinterConnectionState.connected) {
        emit(PrinterDisconnected(devices: _devices));
        emit(PrinterError('Printer turned off', devices: _devices));
        return;
      }
    }

    final name = _connectedName;
    final addr = _connectedAddr;
    emit(PrinterGeneratingInvoice(devices: _devices));

    try {
      final settings = await _settingsService.getSettings();
      final pdfBytes = await InvoicePdfService.generateInvoicePdf(
        invoice: invoice,
        settings: settings,
      );

      final pngBytes = await PdfToImageService.convertFirstPageToImage(pdfBytes);

      emit(PrinterPrinting(deviceName: name, address: addr, width: _currentWidth, devices: _devices));
      _stopWatchdog();
      await _service.printImage(pngBytes, milliseconds: 20000);
      _startWatchdog();

      emit(PrinterPrintSuccess(deviceName: name, address: addr, width: _currentWidth, devices: _devices));
      await Future.delayed(const Duration(seconds: 2));
      if (!isClosed) {
        emit(PrinterConnected(deviceName: name, address: addr, width: _currentWidth, devices: _devices));
      }
    } catch (e) {
      final realState = await _service.getConnectionState();
      final isStillConnected = realState == PrinterConnectionState.connected;
      emit(PrinterError(isStillConnected ? 'Failed to print invoice: $e' : 'Printer turned off', devices: _devices));
      await Future.delayed(const Duration(seconds: 2));
      if (!isClosed && isStillConnected) {
        emit(PrinterConnected(deviceName: name, address: addr, width: _currentWidth, devices: _devices));
      }
    }
  }

  Future<void> printCollection(MoneyCollection collection) async {
    if (state is PrinterConnected) {
      final alive = await _service.pingPrinter();
      if (!alive) await Future.delayed(Duration.zero);
    }

    if (state is! PrinterConnected) {
      final actualState = await _service.getConnectionState();
      if (actualState != PrinterConnectionState.connected) {
        emit(PrinterDisconnected(devices: _devices));
        emit(PrinterError('Printer turned off', devices: _devices));
        return;
      }
    }

    final name = _connectedName;
    final addr = _connectedAddr;
    emit(PrinterGeneratingInvoice(devices: _devices));

    try {
      final settings = await _settingsService.getSettings();
      final pdfBytes = await InvoicePdfService.generateCollectionPdf(
        collection: collection,
        settings: settings,
      );

      final pngBytes = await PdfToImageService.convertFirstPageToImage(pdfBytes);

      emit(PrinterPrinting(deviceName: name, address: addr, width: _currentWidth, devices: _devices));
      _stopWatchdog();
      await _service.printImage(pngBytes);
      _startWatchdog();

      emit(PrinterPrintSuccess(deviceName: name, address: addr, width: _currentWidth, devices: _devices));
      await Future.delayed(const Duration(seconds: 2));
      if (!isClosed) {
        emit(PrinterConnected(deviceName: name, address: addr, width: _currentWidth, devices: _devices));
      }
    } catch (e) {
      final realState = await _service.getConnectionState();
      final isStillConnected = realState == PrinterConnectionState.connected;
      emit(PrinterError(isStillConnected ? 'Failed to print receipt: $e' : 'Printer turned off', devices: _devices));
      await Future.delayed(const Duration(seconds: 2));
      if (!isClosed && isStillConnected) {
        emit(PrinterConnected(deviceName: name, address: addr, width: _currentWidth, devices: _devices));
      }
    }
  }


  @override
  Future<void> close() {
    _stateSub?.cancel();
    _stopWatchdog();
    return super.close();
  }
}
