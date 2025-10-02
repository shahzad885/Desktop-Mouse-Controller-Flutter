// File: android/app/src/main/kotlin/com/example/my_mouse/MainActivity.kt

package com.example.my_mouse

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHidDevice
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.my_mouse/hid"
    private val PERMISSION_REQUEST_CODE = 1001
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var hidDevice: BluetoothHidDevice? = null
    private var connectedDevice: BluetoothDevice? = null
    private var isServiceRunning = false
    private var pendingResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestBluetoothPermissions()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "isHIDServiceRunning" -> {
                    result.success(isServiceRunning && hidDevice != null)
                }
                "startHIDService" -> {
                    if (checkBluetoothPermissions()) {
                        startHIDService(result)
                    } else {
                        pendingResult = result
                        requestBluetoothPermissions()
                    }
                }
                "stopHIDService" -> {
                    stopHIDService()
                    result.success(null)
                }
                "sendMouseMove" -> {
                    val dx = call.argument<Int>("dx") ?: 0
                    val dy = call.argument<Int>("dy") ?: 0
                    sendMouseMove(dx, dy)
                    result.success(null)
                }
                "sendMouseClick" -> {
                    val type = call.argument<String>("type") ?: "left"
                    sendMouseClick(type)
                    result.success(null)
                }
                "sendScroll" -> {
                    val amount = call.argument<Int>("amount") ?: 0
                    sendScroll(amount)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkBluetoothPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED &&
                   ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
                   ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_ADVERTISE) == PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    private fun requestBluetoothPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val permissions = arrayOf(
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_ADVERTISE
            )
            ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            if (allGranted && pendingResult != null) {
                startHIDService(pendingResult!!)
                pendingResult = null
            } else if (pendingResult != null) {
                pendingResult?.error("PERMISSION_DENIED", "Bluetooth permissions required", null)
                pendingResult = null
            }
        }
    }

    private fun startHIDService(result: MethodChannel.Result) {
        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_NOT_AVAILABLE", "Bluetooth not available", null)
            return
        }

        if (!bluetoothAdapter!!.isEnabled) {
            result.error("BLUETOOTH_DISABLED", "Please enable Bluetooth", null)
            return
        }

        try {
            bluetoothAdapter!!.getProfileProxy(this, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    if (profile == BluetoothProfile.HID_DEVICE) {
                        hidDevice = proxy as BluetoothHidDevice
                        registerHIDDevice()
                        isServiceRunning = true
                        result.success(true)
                    }
                }

                override fun onServiceDisconnected(profile: Int) {
                    if (profile == BluetoothProfile.HID_DEVICE) {
                        hidDevice = null
                        isServiceRunning = false
                    }
                }
            }, BluetoothProfile.HID_DEVICE)
        } catch (e: Exception) {
            result.error("HID_ERROR", "Failed to start HID: ${e.message}", null)
        }
    }

    private fun stopHIDService() {
        hidDevice?.let {
            connectedDevice?.let { device ->
                it.disconnect(device)
            }
            bluetoothAdapter?.closeProfileProxy(BluetoothProfile.HID_DEVICE, it)
        }
        hidDevice = null
        connectedDevice = null
        isServiceRunning = false
    }

    private fun registerHIDDevice() {
        val callback = object : BluetoothHidDevice.Callback() {
            override fun onConnectionStateChanged(device: BluetoothDevice, state: Int) {
                if (state == BluetoothProfile.STATE_CONNECTED) {
                    connectedDevice = device
                } else if (state == BluetoothProfile.STATE_DISCONNECTED) {
                    connectedDevice = null
                }
            }
        }

        val executor = { runnable: Runnable -> runnable.run() }

        hidDevice?.registerApp(
            getHidDeviceDescriptor(),
            null,
            null,
            executor,
            callback
        )
    }

    private fun getHidDeviceDescriptor(): android.bluetooth.BluetoothHidDeviceAppSdpSettings {
        return android.bluetooth.BluetoothHidDeviceAppSdpSettings(
            "Bluetooth Mouse",
            "Virtual Mouse",
            "Android",
            BluetoothHidDevice.SUBCLASS1_COMBO,
            getMouseReportDescriptor()
        )
    }

    private fun getMouseReportDescriptor(): ByteArray {
        // Standard USB HID Mouse Report Descriptor
        return byteArrayOf(
            0x05.toByte(), 0x01.toByte(), // Usage Page (Generic Desktop)
            0x09.toByte(), 0x02.toByte(), // Usage (Mouse)
            0xA1.toByte(), 0x01.toByte(), // Collection (Application)
            
            0x09.toByte(), 0x01.toByte(), //   Usage (Pointer)
            0xA1.toByte(), 0x00.toByte(), //   Collection (Physical)
            
            // Buttons
            0x05.toByte(), 0x09.toByte(), //     Usage Page (Buttons)
            0x19.toByte(), 0x01.toByte(), //     Usage Minimum (1)
            0x29.toByte(), 0x03.toByte(), //     Usage Maximum (3)
            0x15.toByte(), 0x00.toByte(), //     Logical Minimum (0)
            0x25.toByte(), 0x01.toByte(), //     Logical Maximum (1)
            0x95.toByte(), 0x03.toByte(), //     Report Count (3)
            0x75.toByte(), 0x01.toByte(), //     Report Size (1)
            0x81.toByte(), 0x02.toByte(), //     Input (Data, Variable, Absolute)
            
            // Padding
            0x95.toByte(), 0x01.toByte(), //     Report Count (1)
            0x75.toByte(), 0x05.toByte(), //     Report Size (5)
            0x81.toByte(), 0x03.toByte(), //     Input (Constant)
            
            // X, Y Movement
            0x05.toByte(), 0x01.toByte(), //     Usage Page (Generic Desktop)
            0x09.toByte(), 0x30.toByte(), //     Usage (X)
            0x09.toByte(), 0x31.toByte(), //     Usage (Y)
            0x15.toByte(), 0x81.toByte(), //     Logical Minimum (-127)
            0x25.toByte(), 0x7F.toByte(), //     Logical Maximum (127)
            0x75.toByte(), 0x08.toByte(), //     Report Size (8)
            0x95.toByte(), 0x02.toByte(), //     Report Count (2)
            0x81.toByte(), 0x06.toByte(), //     Input (Data, Variable, Relative)
            
            // Wheel
            0x09.toByte(), 0x38.toByte(), //     Usage (Wheel)
            0x15.toByte(), 0x81.toByte(), //     Logical Minimum (-127)
            0x25.toByte(), 0x7F.toByte(), //     Logical Maximum (127)
            0x75.toByte(), 0x08.toByte(), //     Report Size (8)
            0x95.toByte(), 0x01.toByte(), //     Report Count (1)
            0x81.toByte(), 0x06.toByte(), //     Input (Data, Variable, Relative)
            
            0xC0.toByte(),                //   End Collection
            0xC0.toByte()                 // End Collection
        )
    }

    private fun sendMouseMove(dx: Int, dy: Int) {
        connectedDevice?.let { device ->
            hidDevice?.let {
                // Clamp values to -127 to 127
                val clampedDx = dx.coerceIn(-127, 127).toByte()
                val clampedDy = dy.coerceIn(-127, 127).toByte()
                
                val report = byteArrayOf(
                    0x00, // Buttons (none pressed)
                    clampedDx,
                    clampedDy,
                    0x00  // Wheel
                )
                
                it.sendReport(device, 0, report)
            }
        }
    }

    private fun sendMouseClick(type: String) {
        connectedDevice?.let { device ->
            hidDevice?.let {
                val button: Byte = when (type) {
                    "left" -> 0x01
                    "right" -> 0x02
                    "middle" -> 0x04
                    else -> 0x00
                }
                
                // Press button
                val pressReport = byteArrayOf(button, 0x00, 0x00, 0x00)
                it.sendReport(device, 0, pressReport)
                
                // Small delay
                Thread.sleep(50)
                
                // Release button
                val releaseReport = byteArrayOf(0x00, 0x00, 0x00, 0x00)
                it.sendReport(device, 0, releaseReport)
            }
        }
    }

    private fun sendScroll(amount: Int) {
        connectedDevice?.let { device ->
            hidDevice?.let {
                val clampedAmount = amount.coerceIn(-127, 127).toByte()
                
                val report = byteArrayOf(
                    0x00, // Buttons
                    0x00, // X movement
                    0x00, // Y movement
                    clampedAmount // Wheel
                )
                
                it.sendReport(device, 0, report)
            }
        }
    }
}