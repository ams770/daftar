import 'dart:async';
import 'package:flutter/services.dart';

enum PrinterConnectionState {
  connected,
  disconnected,
  connecting,
  bluetoothOff,
  error,
}

enum PrinterWidth { inch4, inch3 }

extension PrinterWidthX on PrinterWidth {
  int get pixels => this == PrinterWidth.inch4 ? 832 : 576;
  String get label => this == PrinterWidth.inch4 ? '4"' : '3"';
  double get fontScale => this == PrinterWidth.inch4 ? 1.0 : 0.82;
}

class BluetoothPrinterDevice {
  final String name;
  final String address;

  const BluetoothPrinterDevice({required this.name, required this.address});

  factory BluetoothPrinterDevice.fromMap(Map<dynamic, dynamic> map) {
    return BluetoothPrinterDevice(
      name: map['name'] as String? ?? 'Unknown',
      address: map['address'] as String,
    );
  }
}

abstract class ThermalPrinterService {
  Stream<PrinterConnectionState> get connectionStateStream;
  Stream<double> get progressStream;

  Future<bool> isBluetoothEnabled();
  Future<List<BluetoothPrinterDevice>> scanDevices();
  Future<void> connect(String address);
  Future<void> disconnect();
  Future<PrinterConnectionState> getConnectionState();
  Future<bool> pingPrinter();
  Future<void> printImage(Uint8List bytes, {int milliseconds = 10000});
  Future<void> printLogo();
  Future<void> configurePaperWidth(PrinterWidth width);
  void dispose();
}
