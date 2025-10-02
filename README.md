# 🖱️ Bluetooth Mouse Controller

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter)
![Kotlin](https://img.shields.io/badge/Kotlin-1.8+-7F52FF?style=for-the-badge&logo=kotlin)
![Android](https://img.shields.io/badge/Android-9.0+-3DDC84?style=for-the-badge&logo=android)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**Transform your Android phone into a wireless Bluetooth mouse - No server setup required!**

[Features](#-features) • [Demo](#-demo) • [Installation](#-installation) • [How It Works](#-how-it-works) • [Setup](#-setup-guide) • [Contributing](#-contributing)

</div>

---

## 🌟 Overview

Bluetooth Mouse Controller is a Flutter application that converts your Android smartphone into a fully functional wireless mouse using **Bluetooth HID (Human Interface Device) profile**. Unlike traditional remote mouse apps that require installing server software on your computer, this app works natively through Bluetooth - just pair and play!

### 🎯 What Makes This Different?

- ✅ **No Server Software Required** - Works natively through Bluetooth HID
- ✅ **Zero Configuration** - No IP addresses, no WiFi setup, no desktop apps
- ✅ **Universal Compatibility** - Works with Windows, macOS, Linux, and even Smart TVs
- ✅ **Native Performance** - Direct OS-level mouse control through Bluetooth
- ✅ **Secure Connection** - Standard Bluetooth pairing, no network vulnerabilities
- ✅ **Low Latency** - Bluetooth HID provides near-instant response
- ✅ **Beautiful UI** - Modern, professional interface with smooth animations

---

## ✨ Features

### 🖱️ Complete Mouse Functionality
- **Cursor Movement** - Smooth, responsive touchpad
- **Left Click** - Single tap
- **Right Click** - Long press
- **Double Click** - Double tap
- **Scrolling** - Dedicated scroll buttons
- **Adjustable Sensitivity** - 0.5x to 3.0x multiplier

### 🎨 Professional UI/UX
- Dark theme with gradient backgrounds
- Animated connection indicators
- Haptic feedback on interactions
- Grid-pattern touchpad design
- Real-time connection status
- Smooth transitions and animations

### 🔧 Technical Features
- Native Bluetooth HID implementation
- Android 9+ (API 28+) support
- Runtime permission handling
- Battery efficient
- Automatic reconnection

---

## 📱 Demo

<div align="center">

### Disconnected State
<img src="screenshots/disconnected.png" width="250" alt="Disconnected State"/>

### Connected State
<img src="screenshots/connected.png" width="250" alt="Connected State"/>

### Touchpad in Action
<img src="screenshots/touchpad.png" width="250" alt="Touchpad"/>

</div>

---

## 🔧 How It Works

### The Technology Behind It

This app leverages **Bluetooth HID (Human Interface Device) profile**, the same technology used by commercial Bluetooth mice and keyboards.

```
┌─────────────────┐                    ┌──────────────────┐
│                 │   Bluetooth HID    │                  │
│  Android Phone  │ ═══════════════════│   PC/Laptop      │
│  (HID Device)   │   No Server Needed │   (HID Host)     │
│                 │                    │                  │
└─────────────────┘                    └──────────────────┘
```

### Architecture

1. **Flutter UI Layer** - Handles user interactions and touchpad gestures
2. **Method Channel** - Bridges Flutter and native Android code
3. **Kotlin HID Service** - Implements Bluetooth HID Device profile
4. **HID Report Descriptor** - Defines mouse capabilities (movement, clicks, scroll)
5. **Bluetooth Stack** - Native Android Bluetooth API handles communication

### HID Report Structure

The app sends standard USB HID mouse reports:

```kotlin
[Button State (1 byte)] [X Movement (1 byte)] [Y Movement (1 byte)] [Wheel (1 byte)]
```

- **Button State**: Bit flags for left/right/middle clicks
- **X/Y Movement**: Relative movement (-127 to +127)
- **Wheel**: Scroll amount (-127 to +127)

---

## 🚀 Installation

### Prerequisites

- Android device running **Android 9 (API 28) or higher**
- Computer with Bluetooth capability
- Flutter SDK 3.0+ (for development)

### Download Options

#### Option 1: Pre-built APK (Easiest)
1. Download the latest APK from [Releases](https://github.com/yourusername/bluetooth-mouse/releases)
2. Install on your Android device
3. Enable "Install from Unknown Sources" if prompted

#### Option 2: Build from Source
```bash
# Clone the repository
git clone https://github.com/yourusername/bluetooth-mouse.git
cd bluetooth-mouse

# Install dependencies
flutter pub get

# Build APK
flutter build apk --release

# Or install directly to connected device
flutter run --release
```

---

## 📋 Setup Guide

### Step 1: Install the App
Install the Bluetooth Mouse Controller app on your Android phone.

### Step 2: Grant Permissions
When you first open the app, grant all Bluetooth permissions:
- ✅ Bluetooth Connect
- ✅ Bluetooth Scan  
- ✅ Bluetooth Advertise

### Step 3: Start HID Service
Tap the **"Start Connection"** button in the app. You should see:
- Status changes to "Connected & Ready"
- Bluetooth icon starts pulsing

### Step 4: Pair from Computer

#### Windows
1. Open **Settings → Bluetooth & devices**
2. Click **Add device → Bluetooth**
3. Select your phone from the list
4. Click **Pair**

#### macOS
1. Open **System Preferences → Bluetooth**
2. Find your phone in the devices list
3. Click **Connect**

#### Linux
1. Open **Bluetooth Settings**
2. Click **Add New Device**
3. Select your phone
4. Click **Pair**

### Step 5: Start Using!
Once paired, the touchpad becomes active. Try:
- Swiping to move the cursor
- Tapping for left click
- Long pressing for right click

---

## 🛠️ Development

### Project Structure

```
bluetooth_mouse/
├── lib/
│   └── main.dart                 # Flutter UI and logic
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── AndroidManifest.xml
│               └── kotlin/
│                   └── com/example/my_mouse/
│                       └── MainActivity.kt    # Bluetooth HID implementation
└── README.md
```

### Key Files

#### `lib/main.dart`
- Flutter UI components
- Touchpad gesture handling
- Method channel communication
- State management

#### `android/.../MainActivity.kt`
- Bluetooth HID Device profile implementation
- HID report descriptor definition
- Mouse event transmission
- Connection management

### Dependencies

**Flutter:**
- flutter/material.dart
- flutter/services.dart (Method Channel)

**Android:**
- android.bluetooth.BluetoothHidDevice
- android.bluetooth.BluetoothAdapter
- androidx.core (Permissions)

### Building

```bash
# Debug build
flutter run

# Release build
flutter build apk --release

# Build for specific architecture
flutter build apk --split-per-abi
```

---

## 🔍 Troubleshooting

### "HID Service Inactive" Error
**Solution:** 
- Ensure your device runs Android 9+
- Grant all Bluetooth permissions
- Restart Bluetooth on your phone
- Try restarting the app

### Can't Find Phone in Bluetooth Settings
**Solution:**
- Make sure HID service is started in the app
- Check if Bluetooth is enabled on both devices
- Move devices closer together
- Unpair any previous connections

### Mouse Not Responding
**Solution:**
- Check connection status in the app
- Verify pairing is complete on your computer
- Try adjusting sensitivity
- Restart HID service

### Laggy or Jerky Movement
**Solution:**
- Increase sensitivity setting
- Ensure devices are within 10 meters
- Close other Bluetooth connections
- Check for Bluetooth interference

### Some Samsung Devices Not Working
**Note:** Some Samsung A-series and budget devices may have HID profile disabled by the manufacturer. Check with:
```bash
adb shell dumpsys bluetooth_manager | grep HID
```

---

## 🎯 Supported Platforms

| Platform | Supported | Notes |
|----------|-----------|-------|
| Windows 10/11 | ✅ | Fully supported |
| macOS | ✅ | Fully supported |
| Linux | ✅ | Fully supported |
| Smart TVs | ✅ | Most modern smart TVs work |
| PlayStation/Xbox | ⚠️ | May work, not officially tested |
| iOS | ❌ | iOS doesn't support HID profile for apps |

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit your changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to the branch** (`git push origin feature/AmazingFeature`)
5. **Open a Pull Request**

### Ideas for Contributions
- [ ] iOS support using alternative methods
- [ ] Keyboard functionality
- [ ] Multi-touch gestures
- [ ] Custom button mapping
- [ ] Multiple device profiles
- [ ] Screen mirroring integration

---

## 📝 Technical Details

### Bluetooth HID Report Descriptor

```kotlin
// Standard USB HID Mouse Report Descriptor
val descriptor = byteArrayOf(
    0x05, 0x01,  // Usage Page (Generic Desktop)
    0x09, 0x02,  // Usage (Mouse)
    0xA1, 0x01,  // Collection (Application)
    // ... buttons, movement, wheel definitions
)
```

### Permission Requirements (Android 12+)

```xml
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>
```

### Minimum Requirements
- **Android:** API 28 (Android 9.0) or higher
- **Bluetooth:** 4.0 or higher
- **RAM:** 2GB minimum
- **Flutter:** 3.0.0 or higher

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

---

## 👨‍💻 Author

**Your Name**
- GitHub: [@yourusername](https://github.com/yourusername)
- LinkedIn: [Your Profile](https://linkedin.com/in/yourprofile)
- Email: your.email@example.com

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Android Bluetooth HID API documentation
- The open-source community

---

## ⭐ Star History

If you find this project helpful, please consider giving it a star!

[![Star History Chart](https://api.star-history.com/svg?repos=yourusername/bluetooth-mouse&type=Date)](https://star-history.com/#yourusername/bluetooth-mouse&Date)

---

## 📊 Project Stats

![GitHub stars](https://img.shields.io/github/stars/yourusername/bluetooth-mouse?style=social)
![GitHub forks](https://img.shields.io/github/forks/yourusername/bluetooth-mouse?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/yourusername/bluetooth-mouse?style=social)

---

<div align="center">

**Made with ❤️ and Flutter**

[⬆ Back to Top](#️-bluetooth-mouse-controller)

</div>
