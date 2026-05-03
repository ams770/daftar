import Foundation
import CoreBluetooth
import UIKit

public class BluetoothDataSource: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var bluetoothManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var writableCharacteristic: CBCharacteristic?
    private var discoveredDevices: [BluetoothDeviceEntity] = []
    private var discoveredPeripherals: [String: CBPeripheral] = [:]
    private var scanCompletion: (([BluetoothDeviceEntity]) -> Void)?
    private var connectionSemaphore: DispatchSemaphore?
    private var pendingServiceCount: Int = 0
    private let bluetoothQueue = DispatchQueue(label: "com.easy_blue_printer.bluetooth")
    private var managerReady = false
    private var pendingScanCompletion: (([BluetoothDeviceEntity]) -> Void)?
    private var paperWidth: Int = 384
    private var pendingWriteSemaphore: DispatchSemaphore?
    public var statusCallback: ((String) -> Void)?

    // Accumulates TSPL commands. Flushed as a complete job on commitPrint().
    private var printBuffer = Data()

    // Tracks current Y position in dots (203 DPI).
    // Incremented after each TEXT or BITMAP command.
    private var currentY: Int = 0

    // Paper width in mm derived from paperWidth dots (203 DPI).
    private var paperWidthMm: Int {
        return Int(Double(paperWidth) / 203.0 * 25.4)
    }

    override init() {
        super.init()
        bluetoothManager = CBCentralManager(delegate: self, queue: bluetoothQueue)
    }

    // MARK: - Public methods

    public func scanDevices(completion: @escaping ([BluetoothDeviceEntity]) -> Void) {
        bluetoothQueue.async { [weak self] in
            guard let self = self,
                  let bluetoothManager = self.bluetoothManager else {
                completion([])
                return
            }

            if !self.managerReady {
                self.pendingScanCompletion = completion
                return
            }

            guard bluetoothManager.state == .poweredOn else {
                completion([])
                return
            }

            self.startScan(bluetoothManager: bluetoothManager, completion: completion)
        }
    }

    private func startScan(bluetoothManager: CBCentralManager, completion: @escaping ([BluetoothDeviceEntity]) -> Void) {
        self.discoveredDevices.removeAll()
        // Keep previously discovered peripherals to allow auto-connect by UUID
        self.scanCompletion = completion
        bluetoothManager.scanForPeripherals(withServices: nil, options: nil)

        self.bluetoothQueue.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            self.bluetoothManager?.stopScan()

            if let connected = self.connectedPeripheral,
               let name = connected.name,
               !name.isEmpty {
                let address = connected.identifier.uuidString
                if self.discoveredPeripherals[address] == nil {
                    self.discoveredPeripherals[address] = connected
                    self.discoveredDevices.insert(BluetoothDeviceEntity(name: name, address: address), at: 0)
                }
            }

            self.scanCompletion?(self.discoveredDevices)
            self.scanCompletion = nil
        }
    }

    public func connectToDevice(address: String) -> Bool {
        guard let bluetoothManager = bluetoothManager else { return false }
        
        var peripheral = discoveredPeripherals[address]
        
        // If not in discovered map, try to retrieve it by UUID directly (for auto-connect)
        if peripheral == nil, let uuid = UUID(uuidString: address) {
            let retrieved = bluetoothManager.retrievePeripherals(withIdentifiers: [uuid])
            if let first = retrieved.first {
                peripheral = first
                discoveredPeripherals[address] = first
            }
        }
        
        guard let peripheral = peripheral else { return false }

        bluetoothManager.stopScan()
        writableCharacteristic = nil
        connectionSemaphore = DispatchSemaphore(value: 0)

        bluetoothManager.connect(peripheral, options: nil)

        let result = connectionSemaphore?.wait(timeout: .now() + 10)
        connectionSemaphore = nil

        if result == .success && writableCharacteristic != nil {
            // Reset state for a fresh print job
            currentY = 0
            printBuffer = Data()
            return true
        }
        return false
    }

    public func disconnectFromDevice() -> Bool {
        if let peripheral = connectedPeripheral {
            bluetoothManager?.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        writableCharacteristic = nil
        printBuffer = Data()
        currentY = 0
        return true
    }

    // Builds a TSPL TEXT command and appends it to the print buffer.
    // Arguments are kept identical to the original ESC/POS version.
    // size: 0=small, 1=normal, 2=large, 3=extra-large
    // align: 0=left, 1=center, 2=right
    public func printData(data: String, size: Int, align: Int, bold: Bool) -> Bool {
        let fontSize = fontSizeForIndex(size)
        let lineHeight = fontSize + 8

        // Estimate text width to compute X for alignment
        let estimatedTextWidth = data.count * Int(Double(fontSize) * 0.6)
        let x: Int
        switch align {
        case 1: // Center
            x = max((paperWidth - estimatedTextWidth) / 2, 0)
        case 2: // Right
            x = max(paperWidth - estimatedTextWidth, 0)
        default: // Left
            x = 0
        }

        // Escape double-quotes inside data for TSPL
        let safeData = data.replacingOccurrences(of: "\"", with: "\\\"")

        // Font "4" = bold, "3" = normal (built-in TSPL bitmap fonts)
        let fontIndex = bold ? "4" : "3"
        let cmd = "TEXT \(x),0,\"\(fontIndex)\",\(fontSize),1,1,\"\(safeData)\"\r\n"
        
        if let cmdData = cmd.data(using: .ascii) {
            sendTsplJob(heightDots: lineHeight, content: cmdData)
        }
        return true
    }

    // Advances currentY by blank vertical space — no bytes written to buffer.
    // 40 dots ≈ 5mm at 203 DPI, matching a typical empty receipt line.
    public func printEmptyLine(callTimes: Int) -> Bool {
        let height = 40 * callTimes
        let dummyContent = "\r\n".data(using: .ascii)!
        sendTsplJob(heightDots: height, content: dummyContent)
        return true
    }

    // Wraps buffered TSPL commands in a job header + PRINT footer,
    // then flushes the whole job to the printer in one stream.
    public func commitPrint() -> Bool {
        // With immediate streaming, commitPrint is mostly a cleanup or final margin
        // Send a small final feed to ensure the paper reached the tear-off position
        let footer = "PRINT 1,1\r\n"
        if let footerData = footer.data(using: .ascii) {
             _ = writeData(footerData)
        }

        printBuffer = Data()
        currentY = 0
        return true
    }

    public func isConnected() -> Bool {
        return connectedPeripheral != nil
            && connectedPeripheral?.state == .connected
            && writableCharacteristic != nil
    }

    public func configurePrinter(paperWidth: Int) {
        self.paperWidth = paperWidth
    }

    // Converts image to a TSPL BITMAP command and appends to printBuffer.
    // The full job (text + image) is sent together when commitPrint() is called.
    public func printImage(data: Data, align: Int) -> Bool {
        guard let image = UIImage(data: data) else { return false }
        guard let scaledImage = Utils.scaleImage(image, toWidth: paperWidth) else { return false }
        guard let cgImage = scaledImage.cgImage else { return false }

        let fullWidth = cgImage.width
        let fullHeight = cgImage.height
        let stripHeight = 160 // Slicing into 160px strips (~20mm each) for streaming
        
        var currentOffset = 0
        while currentOffset < fullHeight {
            let remain = fullHeight - currentOffset
            let thisHeight = min(stripHeight, remain)
            
            let sliceRect = CGRect(x: 0, y: currentOffset, width: fullWidth, height: thisHeight)
            if let slice = cgImage.cropping(to: sliceRect) {
                let sliceImage = UIImage(cgImage: slice)
                if let bitmapCmd = encodeBitmapToTspl(sliceImage, align: align, y: 0) {
                    sendTsplJob(heightDots: thisHeight, content: bitmapCmd)
                }
            }
            currentOffset += thisHeight
        }

        return true
    }

    private func sendTsplJob(heightDots: Int, content: Data) {
        let heightMm = max(Int(Double(heightDots) / 203.0 * 25.4), 1)
        let header = [
            "SIZE \(paperWidthMm) mm,\(heightMm) mm",
            "GAP 0 mm,0 mm",
            "DIRECTION 0",
            "REFERENCE 0,0",
            "CLS"
        ].joined(separator: "\r\n") + "\r\n"
        
        var job = Data()
        if let headerData = header.data(using: .ascii) {
            job.append(headerData)
        }
        job.append(content)
        if let footerData = "PRINT 1,1\r\n".data(using: .ascii) {
            job.append(footerData)
        }
        
        _ = writeData(job)
    }

    // MARK: - Private helpers

    // Encodes a UIImage into a TSPL BITMAP command.
    // Format: BITMAP x,y,widthBytes,height,mode,<binary pixel data>
    // mode 0 = overwrite. 1 bit per pixel, MSB first, 1=black 0=white.
    private func encodeBitmapToTspl(_ image: UIImage, align: Int, y: Int) -> Data? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let widthBytes = (width + 7) / 8

        let x: Int
        switch align {
        case 1: x = max(((paperWidth / 8) - widthBytes) / 2, 0) * 8
        case 2: x = max((paperWidth / 8) - widthBytes, 0) * 8
        default: x = 0
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Flatten transparency to white
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var bitmapBytes = Data(capacity: widthBytes * height)

        for row in 0..<height {
            for byteIdx in 0..<widthBytes {
                var byte: UInt8 = 0
                for bit in 0..<8 {
                    let col = byteIdx * 8 + bit
                    if col < width {
                        let pixelIndex = (row * width + col) * 4
                        let r = Int(pixelData[pixelIndex])
                        let g = Int(pixelData[pixelIndex + 1])
                        let b = Int(pixelData[pixelIndex + 2])

                        let luminance = (r * 299 + g * 587 + b * 114) / 1000

                        // INVERTED LOGIC FOR YOUR PRINTER:
                        // Based on your result, your printer needs bit '0' to print Black.
                        // So, we set the bit to '1' only if the pixel is LIGHT (Luminance >= 128).
                        if luminance >= 128 {
                            byte |= (0x80 >> bit)
                        }
                    } else {
                        // Padding bits outside the image width should be '1' (White)
                        byte |= (0x80 >> bit)
                    }
                }
                bitmapBytes.append(byte)
            }
        }

        // TSPL BITMAP header
        let header = "BITMAP \(x),\(y),\(widthBytes),\(height),0,"
        var result = Data()
        if let headerData = header.data(using: .ascii) {
            result.append(headerData)
        }

        result.append(bitmapBytes)

        if let crlf = "\r\n".data(using: .ascii) {
            result.append(crlf)
        }

        return result
    }

    private func fontSizeForIndex(_ size: Int) -> Int {
        switch size {
        case 0: return 24
        case 1: return 32
        case 2: return 48
        case 3: return 64
        default: return 32
        }
    }

    private func writeData(_ data: Data) -> Bool {
        guard let peripheral = connectedPeripheral,
              let characteristic = writableCharacteristic else { return false }

        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse

        let mtu = peripheral.maximumWriteValueLength(for: writeType)
        let chunkSize = max(mtu, 20) // Use full MTU, no 128-byte cap
        var offset = 0

        while offset < data.count {
            let end = min(offset + chunkSize, data.count)
            let chunk = data.subdata(in: offset..<end)

            var attempt = 0
            while true {
                let ok = writeChunk(chunk, to: peripheral, characteristic: characteristic, type: writeType)
                if ok { break }
                attempt += 1
                if attempt > 2 { return false }
            }

            offset = end
        }
        return true
    }

    private func writeChunk(
        _ chunk: Data,
        to peripheral: CBPeripheral,
        characteristic: CBCharacteristic,
        type writeType: CBCharacteristicWriteType
    ) -> Bool {
        if writeType == .withResponse {
            let semaphore = DispatchSemaphore(value: 0)
            pendingWriteSemaphore = semaphore
            peripheral.writeValue(chunk, for: characteristic, type: .withResponse)
            let result = semaphore.wait(timeout: .now() + 5.0)
            pendingWriteSemaphore = nil
            return result == .success
        } else {
            // Write without response: check if internal buffer is full
            if !peripheral.canSendWriteWithoutResponse {
                let semaphore = DispatchSemaphore(value: 0)
                pendingWriteSemaphore = semaphore
                let result = semaphore.wait(timeout: .now() + 1) // 2s is enough for BLE
                pendingWriteSemaphore = nil
                if result == .timedOut { 
                    print("Warning: Bluetooth write timed out while waiting for readiness")
                }
            }
            peripheral.writeValue(chunk, for: characteristic, type: .withoutResponse)
            return true
        }
    }

    // MARK: - CBCentralManagerDelegate

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            managerReady = true
            statusCallback?("disconnected") // Assume ready but disconnected
            if let pending = pendingScanCompletion {
                pendingScanCompletion = nil
                startScan(bluetoothManager: central, completion: pending)
            }
        case .poweredOff:
            print("Bluetooth is powered off")
            statusCallback?("bluetooth_off")
        case .unauthorized:
            print("Bluetooth is not authorized")
        case .unsupported:
            print("Bluetooth is not supported on this device")
        case .resetting:
            print("Bluetooth state is resetting")
        case .unknown:
            print("Bluetooth state is unknown")
        @unknown default:
            print("A new Bluetooth state was added")
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                                advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name, !name.isEmpty, name != "Unknown" else { return }
        let address = peripheral.identifier.uuidString
        if discoveredPeripherals[address] == nil {
            discoveredPeripherals[address] = peripheral
            discoveredDevices.append(BluetoothDeviceEntity(name: name, address: address))
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        statusCallback?("connected")
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionSemaphore?.signal()
        statusCallback?("disconnected")
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        writableCharacteristic = nil
        statusCallback?("disconnected")
    }

    // MARK: - CBPeripheralDelegate

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services, !services.isEmpty else {
            connectionSemaphore?.signal()
            return
        }
        pendingServiceCount = services.count
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        pendingWriteSemaphore?.signal()
    }

    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        pendingWriteSemaphore?.signal()
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if writableCharacteristic == nil, let characteristics = service.characteristics {
            let knownCharUUIDs: [CBUUID] = [
                CBUUID(string: "49535343-8841-43F4-A8D4-ECBE34729BB3"),
                CBUUID(string: "BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F"),
            ]

            for char in characteristics {
                if knownCharUUIDs.contains(char.uuid) &&
                    (char.properties.contains(.write) || char.properties.contains(.writeWithoutResponse)) {
                    writableCharacteristic = char
                    break
                }
            }

            if writableCharacteristic == nil {
                for char in characteristics {
                    if char.properties.contains(.writeWithoutResponse) || char.properties.contains(.write) {
                        writableCharacteristic = char
                        break
                    }
                }
            }
        }

        pendingServiceCount -= 1
        if pendingServiceCount <= 0 {
            connectionSemaphore?.signal()
        }
    }
}