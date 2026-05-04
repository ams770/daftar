import 'dart:async';
import 'package:flutter/services.dart';
import 'package:easy_blue_printer/easy_blue_printer.dart';
import 'thermal_printer_service.dart';

class IosThermalPrinterService implements ThermalPrinterService {
  final EasyBluePrinter _printer = EasyBluePrinter.instance;

  final StreamController<PrinterConnectionState> _stateController =
      StreamController<PrinterConnectionState>.broadcast();
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  List<BluetoothDevice> _scannedDevices = [];

  IosThermalPrinterService() {
    _printer.connectionStatusStream.listen((status) {
      switch (status) {
        case 'connected':
          _stateController.add(PrinterConnectionState.connected);
          break;
        case 'disconnected':
          _stateController.add(PrinterConnectionState.disconnected);
          break;
        case 'connecting':
          _stateController.add(PrinterConnectionState.connecting);
          break;
        case 'bluetooth_off':
          _stateController.add(PrinterConnectionState.bluetoothOff);
          break;
      }
    });
  }

  @override
  Stream<PrinterConnectionState> get connectionStateStream =>
      _stateController.stream;

  @override
  Stream<double> get progressStream => _progressController.stream;

  @override
  Future<bool> isBluetoothEnabled() async {
    return true;
  }

  @override
  Future<List<BluetoothPrinterDevice>> scanDevices() async {
    try {
      _scannedDevices = await _printer.getPairedDevices();
      return _scannedDevices
          .map((d) => BluetoothPrinterDevice(name: d.name, address: d.address))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> connect(String address) async {
    _stateController.add(PrinterConnectionState.connecting);
    try {
      final device = BluetoothDevice(name: 'Printer', address: address);
      final success = await _printer.connectToDevice(device);
      if (success) {
        _stateController.add(PrinterConnectionState.connected);
      } else {
        _stateController.add(PrinterConnectionState.disconnected);
        throw Exception("Failed to connect to printer at $address");
      }
    } catch (e) {
      _stateController.add(PrinterConnectionState.disconnected);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _printer.disconnectFromDevice();
    _stateController.add(PrinterConnectionState.disconnected);
  }

  @override
  Future<PrinterConnectionState> getConnectionState() async {
    final connected = await _printer.isConnected();
    return connected
        ? PrinterConnectionState.connected
        : PrinterConnectionState.disconnected;
  }

  @override
  Future<bool> pingPrinter() async {
    return true;
  }

  @override
  Future<void> printImage(Uint8List bytes, {int milliseconds = 10000}) async {
    await _printer.printImage(bytes: bytes, textAlign: TA.left);
  }

  @override
  Future<void> printLogo() async {
    // Implement if needed
  }

  @override
  Future<void> configurePaperWidth(PrinterWidth width) async {
    await _printer.configurePrinter(PaperConfig(widthPixels: width.pixels));
  }

  @override
  void dispose() {
    _stateController.close();
    _progressController.close();
  }
}
