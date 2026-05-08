import 'dart:async';

import 'package:flutter/services.dart';

enum PrinterConnectionState {
  connected,
  disconnected,
  connecting,
  bluetoothOff,
  error,
}

enum PrinterWidth { inch4, inch3, inch2 }

extension PrinterWidthX on PrinterWidth {
  int get pixels {
    switch (this) {
      case PrinterWidth.inch4:
        return 832;
      case PrinterWidth.inch3:
        return 576;
      case PrinterWidth.inch2:
        return 384;
    }
  }

  String get label {
    switch (this) {
      case PrinterWidth.inch4:
        return '4"';
      case PrinterWidth.inch3:
        return '3"';
      case PrinterWidth.inch2:
        return '2"';
    }
  }

  double get fontScale {
    switch (this) {
      case PrinterWidth.inch4:
        return 1.0;
      case PrinterWidth.inch3:
        return 0.82;
      case PrinterWidth.inch2:
        return 0.65;
    }
  }
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

  Future<bool> requestPermissions();
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
