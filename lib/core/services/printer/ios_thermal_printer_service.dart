import 'dart:async';

import 'package:flutter/services.dart';

import 'thermal_printer_service.dart';

class IosThermalPrinterService implements ThermalPrinterService {
  static const _channel = MethodChannel('com.bennu.daftar/printer');
  static const _eventChannel = EventChannel('com.bennu.daftar/printer_state');

  final StreamController<PrinterConnectionState> _stateController =
      StreamController<PrinterConnectionState>.broadcast();
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  IosThermalPrinterService() {
    _eventChannel.receiveBroadcastStream().listen((status) {
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
  Future<bool> requestPermissions() async {
    // iOS handles permissions via Info.plist and triggers them on first use.
    // We can just return true here or call the native method which returns a string.
    await _channel.invokeMethod('requestBluetoothPermissions');
    return true;
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    return true;
  }

  @override
  Future<List<BluetoothPrinterDevice>> scanDevices() async {
    try {
      final List<dynamic> devices = await _channel.invokeMethod(
        'getPairedDevices',
      );
      return devices.map((d) {
        // iOS implementation returns "Name (Address)" string
        final str = d.toString();
        final match = RegExp(r'(.+)\s\((.+)\)').firstMatch(str);
        if (match != null) {
          return BluetoothPrinterDevice(
            name: match.group(1)!,
            address: match.group(2)!,
          );
        }
        return BluetoothPrinterDevice(name: str, address: str);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> connect(String address) async {
    _stateController.add(PrinterConnectionState.connecting);
    try {
      final bool success = await _channel.invokeMethod('connectToDevice', {
        'address': address,
      });
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
    await _channel.invokeMethod('disconnectFromDevice');
    _stateController.add(PrinterConnectionState.disconnected);
  }

  @override
  Future<PrinterConnectionState> getConnectionState() async {
    final bool connected = await _channel.invokeMethod('isConnected');
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
    await _channel.invokeMethod('printImage', {
      'data': bytes,
      'textAlign': 0, // Left
    });
    // For iOS we might need commitPrint if the SDK requires it
    await _channel.invokeMethod('commitPrint');
  }

  @override
  Future<void> printLogo() async {
    // Implement if needed
  }

  @override
  Future<void> configurePaperWidth(PrinterWidth width) async {
    await _channel.invokeMethod('configurePrinter', {
      'paperWidth': width.pixels,
    });
  }

  @override
  void dispose() {
    _stateController.close();
    _progressController.close();
  }
}
