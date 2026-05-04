package com.bennu.daftar

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.rt.printerlibrary.bean.BluetoothEdrConfigBean
import com.rt.printerlibrary.cmd.Cmd
import com.rt.printerlibrary.cmd.EscFactory
import com.rt.printerlibrary.enumerate.BmpPrintMode
import com.rt.printerlibrary.enumerate.CommonEnum
import com.rt.printerlibrary.enumerate.ConnectStateEnum
import com.rt.printerlibrary.connect.PrinterInterface
import com.rt.printerlibrary.exception.SdkException
import com.rt.printerlibrary.factory.cmd.CmdFactory
import com.rt.printerlibrary.factory.connect.BluetoothFactory
import com.rt.printerlibrary.factory.printer.ThermalPrinterFactory
import com.rt.printerlibrary.observer.PrinterObserver
import com.rt.printerlibrary.observer.PrinterObserverManager
import com.rt.printerlibrary.printer.RTPrinter
import com.rt.printerlibrary.setting.BitmapSetting
import com.rt.printerlibrary.setting.CommonSetting
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class ThermalPrinterPlugin(private val activity: Activity) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler, PrinterObserver {

    companion object {
        private const val TAG = "ThermalPrinterPlugin"
        private const val METHOD_CHANNEL = "com.bennu.daftar/printer"
        private const val EVENT_CHANNEL = "com.bennu.daftar/printer_state"

        // 4 inch paper = 104mm = 832 dots (8 dots/mm) -> Adjusted to 800px for safety padding
        private const val PRINT_WIDTH_DOTS = 800 
        private const val PRINT_WIDTH_MM = 104

        fun register(activity: Activity, flutterEngine: FlutterEngine) {
            val plugin = ThermalPrinterPlugin(activity)
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                METHOD_CHANNEL
            ).setMethodCallHandler(plugin)
            EventChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                EVENT_CHANNEL
            ).setStreamHandler(plugin)
        }
    }

    private var eventSink: EventChannel.EventSink? = null
    private var rtPrinter: RTPrinter<Any>? = null
    private var printWidthDots: Int = PRINT_WIDTH_DOTS
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

    private var lastConnectedAddress: String? = null
    private var isConnecting = false
    private var pendingConnectResult: MethodChannel.Result? = null

    // ── Bluetooth Adapter State Receiver ──────────────────────────────────────
    private val bluetoothStateReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: android.content.Intent?) {
            if (intent?.action == BluetoothAdapter.ACTION_STATE_CHANGED) {
                val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
                Log.d(TAG, "Bluetooth state changed: $state")
                if (state == BluetoothAdapter.STATE_OFF || state == BluetoothAdapter.STATE_TURNING_OFF) {
                    Log.d(TAG, "Bluetooth turned off - forcing disconnection state")
                    updateState("bluetooth_off")
                    rtPrinter?.disConnect()
                } else if (state == BluetoothAdapter.STATE_ON) {
                    Log.d(TAG, "Bluetooth turned on")
                    updateState("disconnected")
                }
            }
        }
    }

    init {
        val printerFactory = ThermalPrinterFactory()
        @Suppress("UNCHECKED_CAST")
        rtPrinter = printerFactory.create() as? RTPrinter<Any>
        PrinterObserverManager.getInstance().add(this)

        val prefs = activity.getSharedPreferences("printer_prefs", Context.MODE_PRIVATE)
        lastConnectedAddress = prefs.getString("last_address", null)

        // Register receiver
        val filter = android.content.IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        activity.registerReceiver(bluetoothStateReceiver, filter)
    }

    // ──────────────────────────────────────────────────────────────
    // MethodChannel.MethodCallHandler
    // ──────────────────────────────────────────────────────────────
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "onMethodCall: ${call.method}")
        when (call.method) {
            "scanDevices"       -> scanDevices(result)
            "connect"           -> connect(call.argument<String>("address"), result)
            "disconnect"        -> disconnect(result)
            "printImage"        -> {
                val bytes = call.arguments
                when (bytes) {
                    is ByteArray -> printImage(bytes, result)
                    else -> result.error("INVALID_TYPE",
                        "Expected ByteArray, got ${bytes?.javaClass?.name}", null)
                }
            }
            "getConnectionState" -> getConnectionState(result)
            "pingPrinter"       -> pingPrinter(result)
            "isBluetoothEnabled" -> result.success(bluetoothAdapter?.isEnabled == true)
            "setPaperWidth" -> {
                val dots = call.argument<Int>("widthDots") ?: PRINT_WIDTH_DOTS
                printWidthDots = dots
                result.success(null)
            }
            "requestBluetoothPermissions" -> {
                requestBluetoothPermissions(result)
            }
            else                 -> result.notImplemented()
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Scan
    // ──────────────────────────────────────────────────────────────
    private fun scanDevices(result: MethodChannel.Result) {
        if (!hasBluetoothPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions are not granted", null)
            return
        }
        val devices = mutableListOf<Map<String, String>>()
        bluetoothAdapter?.bondedDevices?.forEach { device ->
            devices.add(
                mapOf(
                    "name"    to (device.name ?: "Unknown"),
                    "address" to device.address
                )
            )
        }
        Log.d(TAG, "scanDevices: found ${devices.size} bonded devices")
        result.success(devices)
    }

    // ──────────────────────────────────────────────────────────────
    // Connect
    // ──────────────────────────────────────────────────────────────
    private fun connect(address: String?, result: MethodChannel.Result) {
        if (address == null) {
            result.error("INVALID_ARGUMENT", "Address is null", null)
            return
        }

        // Check if already connected to this address
        if (rtPrinter?.connectState == ConnectStateEnum.Connected && lastConnectedAddress == address) {
            result.success(null)
            return
        }

        val device = bluetoothAdapter?.getRemoteDevice(address)
        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "No device with address $address", null)
            return
        }

        lastConnectedAddress = address
        activity.getSharedPreferences("printer_prefs", Context.MODE_PRIVATE)
            .edit().putString("last_address", address).apply()

        isConnecting = true
        pendingConnectResult = result // Wait for observer callback
        updateState("connecting")

        executor.execute {
            try {
                val config = BluetoothEdrConfigBean(device)
                val pi = BluetoothFactory().create()
                pi.configObject = config
                rtPrinter?.setPrinterInterface(pi)
                rtPrinter?.connect(config)
                // We DON'T call result.success here. We wait for printerObserverCallback.
            } catch (e: Exception) {
                Log.e(TAG, "connect error: ${e.message}", e)
                isConnecting = false
                mainHandler.post {
                    updateState("disconnected")
                    pendingConnectResult?.error("CONNECT_FAILED", e.message, null)
                    pendingConnectResult = null
                }
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Disconnect
    // ──────────────────────────────────────────────────────────────
    private fun disconnect(result: MethodChannel.Result) {
        lastConnectedAddress = null
        isConnecting = false
        activity.getSharedPreferences("printer_prefs", Context.MODE_PRIVATE)
            .edit().remove("last_address").apply()

        executor.execute {
            try {
                rtPrinter?.disConnect()
            } catch (e: Exception) {
                Log.e(TAG, "disconnect error: ${e.message}")
            }
            mainHandler.post {
                result.success(null)
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Print image
    // ──────────────────────────────────────────────────────────────
    private fun printImage(imageBytes: ByteArray, result: MethodChannel.Result) {
        Log.d(TAG, "printImage: received ${imageBytes.size} bytes")

        if (rtPrinter?.connectState != ConnectStateEnum.Connected) {
            result.error("NOT_CONNECTED", "Printer is not connected", null)
            return
        }

        executor.execute {
            try {
                // 1. Decode bitmap
                val raw: Bitmap? = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                if (raw == null) {
                    mainHandler.post { result.error("DECODE_FAILED", "Could not decode image", null) }
                    return@execute
                }

                // 2. Scale bitmap
                val scale = printWidthDots.toFloat() / raw.width.toFloat()
                val newH = (raw.height * scale).toInt().coerceAtLeast(1)
                val scaled = Bitmap.createScaledBitmap(raw, printWidthDots, newH, true)

                // 3. *** CRITICAL: Flatten onto solid white ARGB_8888 canvas ***
                // This removes transparency (alpha channel) which thermal printers
                // render as black. We composite the logo onto a white "whiteboard".
                val bmpWhite = Bitmap.createBitmap(printWidthDots, newH, Bitmap.Config.ARGB_8888)
                bmpWhite.eraseColor(android.graphics.Color.WHITE)
                val canvas = android.graphics.Canvas(bmpWhite)
                canvas.drawBitmap(scaled, 0f, 0f, null)
                val bitmap: Bitmap = bmpWhite

                // 3. Build Command
                val cmdFactory: CmdFactory = EscFactory()
                val cmd: Cmd = cmdFactory.create()
                cmd.append(cmd.getHeaderCmd())

                val commonSetting = CommonSetting()
                commonSetting.setAlign(CommonEnum.ALIGN_LEFT)
                cmd.append(cmd.getCommonSettingCmd(commonSetting))

                val bitmapSetting = BitmapSetting()
                bitmapSetting.bmpPrintMode = BmpPrintMode.MODE_SINGLE_COLOR
                bitmapSetting.bimtapLimitWidth = printWidthDots

                try {
                    cmd.append(cmd.getBitmapCmd(bitmapSetting, bitmap))
                } catch (sdkEx: SdkException) {
                    mainHandler.post { result.error("SDK_ERROR", sdkEx.message, null) }
                    return@execute
                }

                cmd.append(cmd.getLFCRCmd())
                cmd.append(cmd.getCmdCutNew())

                val cmdBytes = cmd.getAppendCmds()
                Log.d(TAG, "Sending ${cmdBytes.size} command bytes in chunks")

                // 4. Chunked Writing to prevent "Broken pipe" / Buffer Overflow
                val chunkSize = 1024
                var offset = 0
                while (offset < cmdBytes.size) {
                    val length = Math.min(chunkSize, cmdBytes.size - offset)
                    val chunk = cmdBytes.copyOfRange(offset, offset + length)
                    
                    if (rtPrinter?.connectState != ConnectStateEnum.Connected) {
                        throw Exception("Printer disconnected during print")
                    }
                    
                    rtPrinter?.writeMsg(chunk)
                    offset += length
                    
                    // Small delay between chunks to let the printer buffer clear
                    Thread.sleep(15) 
                }

                mainHandler.post { result.success(null) }
            } catch (e: Exception) {
                Log.e(TAG, "printImage error: ${e.message}", e)
                // The physical connection is broken — force-disconnect so the SDK
                // state no longer reports Connected, and notify Flutter immediately.
                try { rtPrinter?.disConnect() } catch (_: Exception) {}
                updateState("disconnected")
                mainHandler.post { result.error("PRINT_FAILED", e.message, null) }
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Ping printer — actively probes physical connection liveness
    // ──────────────────────────────────────────────────────────────
    private fun pingPrinter(result: MethodChannel.Result) {
        if (rtPrinter?.connectState != ConnectStateEnum.Connected) {
            result.success(false)
            return
        }
        executor.execute {
            try {
                // Send an empty ESC/POS NUL byte. If the socket is broken this throws.
                rtPrinter?.writeMsg(byteArrayOf(0x00))
                mainHandler.post { result.success(true) }
            } catch (e: Exception) {
                Log.w(TAG, "pingPrinter: connection dead — ${e.message}")
                try { rtPrinter?.disConnect() } catch (_: Exception) {}
                updateState("disconnected")
                mainHandler.post { result.success(false) }
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Connection state query
    // ──────────────────────────────────────────────────────────────
    private fun getConnectionState(result: MethodChannel.Result) {
        val adapterEnabled = bluetoothAdapter?.isEnabled == true
        val state = when {
            !adapterEnabled -> "bluetooth_off"
            rtPrinter?.connectState == ConnectStateEnum.Connected -> "connected"
            isConnecting -> "connecting"
            else -> "disconnected"
        }
        result.success(state)
    }

    private fun updateState(state: String) {
        mainHandler.post { eventSink?.success(state) }
    }

    // ──────────────────────────────────────────────────────────────
    // EventChannel.StreamHandler
    // ──────────────────────────────────────────────────────────────
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        
        // Check current state and notify
        val currentState = when {
            bluetoothAdapter?.isEnabled != true -> "bluetooth_off"
            rtPrinter?.connectState == ConnectStateEnum.Connected -> "connected"
            isConnecting -> "connecting"
            else -> "disconnected"
        }
        eventSink?.success(currentState)

        // Auto-connect on start if we have a saved address
        if (currentState == "disconnected" && !isConnecting) {
            lastConnectedAddress?.let { address ->
                Log.d(TAG, "onListen: Attempting auto-connect to $address")
                connect(address, object : MethodChannel.Result {
                    override fun success(result: Any?) { Log.d(TAG, "Auto-connect success") }
                    override fun error(c: String, m: String?, d: Any?) { Log.e(TAG, "Auto-connect failed: $m") }
                    override fun notImplemented() {}
                })
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // ──────────────────────────────────────────────────────────────
    // PrinterObserver
    // ──────────────────────────────────────────────────────────────
    override fun printerObserverCallback(printerInterface: PrinterInterface<*>?, state: Int) {
        Log.d(TAG, "printerObserverCallback state=$state")
        when (state) {
            CommonEnum.CONNECT_STATE_SUCCESS -> {
                isConnecting = false
                if (lastConnectedAddress == null) {
                    Log.d(TAG, "Ignoring CONNECT_STATE_SUCCESS as lastConnectedAddress is null")
                    return
                }
                mainHandler.post {
                    pendingConnectResult?.success(null)
                    pendingConnectResult = null
                }
                updateState("connected")
            }
            CommonEnum.CONNECT_STATE_INTERRUPTED, -1 -> {
                // Some SDKs use -1 for general disconnect
                isConnecting = false
                mainHandler.post {
                    pendingConnectResult?.error("CONNECT_LOST", "Connection interrupted or lost", null)
                    pendingConnectResult = null
                }
                updateState("disconnected")
                
                // Robust Auto-reconnect: Only if lastConnectedAddress is set (meaning we didn't explicitly disconnect)
                lastConnectedAddress?.let { address ->
                    mainHandler.removeCallbacksAndMessages(null) // Clear previous retry tasks
                    mainHandler.postDelayed({
                        if (lastConnectedAddress != null && !isConnecting && rtPrinter?.connectState != ConnectStateEnum.Connected) {
                            Log.d(TAG, "Auto-reconnecting to $address after interruption")
                            connect(address, object : MethodChannel.Result {
                                override fun success(result: Any?) {}
                                override fun error(c: String, m: String?, d: Any?) {}
                                override fun notImplemented() {}
                            })
                        }
                    }, 2_000) // retry after 2 seconds
                }
            }
        }
    }

    override fun printerReadMsgCallback(printerInterface: PrinterInterface<*>?, bytes: ByteArray?) {
        // Not needed for printing
    }

    private fun hasBluetoothPermissions(): Boolean {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) { // Android 12+
            androidx.core.content.ContextCompat.checkSelfPermission(activity, android.Manifest.permission.BLUETOOTH_CONNECT) == android.content.pm.PackageManager.PERMISSION_GRANTED &&
                    androidx.core.content.ContextCompat.checkSelfPermission(activity, android.Manifest.permission.BLUETOOTH_SCAN) == android.content.pm.PackageManager.PERMISSION_GRANTED
        } else {
            true // Android 11 or below
        }
    }

    private fun requestBluetoothPermissions(result: MethodChannel.Result) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            androidx.core.app.ActivityCompat.requestPermissions(
                activity,
                arrayOf(
                    android.Manifest.permission.BLUETOOTH_CONNECT,
                    android.Manifest.permission.BLUETOOTH_SCAN
                ),
                101
            )
            result.success("Permission request sent")
        } else {
            result.success("Permissions not required for this Android version")
        }
    }
}
