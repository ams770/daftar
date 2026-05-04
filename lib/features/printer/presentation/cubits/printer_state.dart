import '../../../../core/services/printer/thermal_printer_service.dart';

abstract class PrinterState {
  final List<BluetoothPrinterDevice> devices;
  PrinterState({this.devices = const []});
}

class PrinterInitial extends PrinterState {
  PrinterInitial({super.devices});
}

class PrinterScanning extends PrinterState {
  PrinterScanning({super.devices});
}

class PrinterSearching extends PrinterState {
  final String address;
  final String? name;
  PrinterSearching({required this.address, this.name, super.devices});
}

class PrinterGeneratingInvoice extends PrinterState {
  PrinterGeneratingInvoice({super.devices});
}

class PrinterScanned extends PrinterState {
  PrinterScanned(List<BluetoothPrinterDevice> devices)
    : super(devices: devices);
}

class PrinterConnecting extends PrinterState {
  final String address;
  final String? deviceName;
  final PrinterWidth? width;
  PrinterConnecting(
    this.address, {
    this.deviceName,
    this.width,
    super.devices,
  });
}

class PrinterConnected extends PrinterState {
  final String? deviceName;
  final String? address;
  final PrinterWidth? width;
  PrinterConnected({this.deviceName, this.address, this.width, super.devices});
}

class PrinterDisconnected extends PrinterState {
  PrinterDisconnected({super.devices});
}

class PrinterPrinting extends PrinterState {
  final String? deviceName;
  final String? address;
  final PrinterWidth? width;
  PrinterPrinting({this.deviceName, this.address, this.width, super.devices});
}

class PrinterPrintSuccess extends PrinterState {
  final String? deviceName;
  final String? address;
  final PrinterWidth? width;
  PrinterPrintSuccess({
    this.deviceName,
    this.address,
    this.width,
    super.devices,
  });
}

class PrinterBluetoothOff extends PrinterState {
  PrinterBluetoothOff({super.devices});
}

class PrinterError extends PrinterState {
  final String message;
  PrinterError(this.message, {super.devices});
}
