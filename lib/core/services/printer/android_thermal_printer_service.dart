import 'dart:async';
import 'package:flutter/services.dart';
import 'thermal_printer_service.dart';

class AndroidThermalPrinterService implements ThermalPrinterService {
  static const _channel = MethodChannel('com.bennu.daftar/printer');
  static const _stateChannel = EventChannel('com.bennu.daftar/printer_state');

  // ── State stream ──────────────────────────────────────────────────────────
  final StreamController<PrinterConnectionState> _stateController =
      StreamController<PrinterConnectionState>.broadcast();
  StreamSubscription<dynamic>? _stateSubscription;
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  AndroidThermalPrinterService() {
    _stateSubscription = _stateChannel.receiveBroadcastStream().listen((
      dynamic event,
    ) {
      if (event is String) {
        switch (event) {
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
          default:
            _stateController.add(PrinterConnectionState.disconnected);
        }
      } else if (event is Map) {
        if (event['type'] == 'progress') {
          final double progress = (event['value'] as num).toDouble();
          _progressController.add(progress);
        }
      }
    });
  }

  @override
  Stream<PrinterConnectionState> get connectionStateStream =>
      _stateController.stream;

  @override
  Stream<double> get progressStream => _progressController.stream;

  // ── Bluetooth Permissions ─────────────────────────────────────────────────
  @override
  Future<bool> requestPermissions() async {
    try {
      await _channel.invokeMethod('requestBluetoothPermissions');
      return true;
    } on PlatformException {
      return false;
    }
  }

  // ── Bluetooth Status ──────────────────────────────────────────────────────
  @override
  Future<bool> isBluetoothEnabled() async {
    try {
      final dynamic result = await _channel.invokeMethod('isBluetoothEnabled');
      if (result is bool) return result;
      if (result is int) return result == 1;
      return false;
    } on PlatformException {
      return false;
    }
  }

  // ── Device discovery ──────────────────────────────────────────────────────
  @override
  Future<List<BluetoothPrinterDevice>> scanDevices() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('scanDevices');
      if (result == null) return [];
      return result
          .map((e) => BluetoothPrinterDevice.fromMap(e as Map))
          .toList();
    } on PlatformException {
      return [];
    }
  }

  // ── Connection ────────────────────────────────────────────────────────────
  @override
  Future<void> connect(String address) async {
    await _channel.invokeMethod('connect', {'address': address});
  }

  @override
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
    } on PlatformException {
      // ignore
    }
  }

  @override
  Future<PrinterConnectionState> getConnectionState() async {
    try {
      final String? result = await _channel.invokeMethod('getConnectionState');
      switch (result) {
        case 'connected':
          return PrinterConnectionState.connected;
        case 'connecting':
          return PrinterConnectionState.connecting;
        case 'bluetooth_off':
          return PrinterConnectionState.bluetoothOff;
        default:
          return PrinterConnectionState.disconnected;
      }
    } on PlatformException {
      return PrinterConnectionState.disconnected;
    }
  }

  @override
  Future<bool> pingPrinter() async {
    try {
      final dynamic result = await _channel.invokeMethod('pingPrinter');
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  // ── Print ─────────────────────────────────────────────────────────────────

  /// Sends custom image bytes to the thermal printer.
  @override
  Future<void> printImage(Uint8List bytes, {int milliseconds = 10000}) async {
    await _channel.invokeMethod('printImage', bytes);
  }

  /// Sends a dummy logo (or can be updated to send actual logo)
  @override
  Future<void> printLogo() async {
    // This can be implemented by loading an asset and calling printImage
  }

  @override
  Future<void> configurePaperWidth(PrinterWidth width) async {
    await _channel.invokeMethod('setPaperWidth', {'widthDots': width.pixels});
  }

  // ── Dispose ───────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _stateSubscription?.cancel();
    _stateController.close();
    _progressController.close();
  }
}
