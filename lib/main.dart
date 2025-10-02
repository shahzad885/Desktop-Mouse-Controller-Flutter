import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

void main() {
  runApp(const BluetoothMouseApp());
}

class BluetoothMouseApp extends StatelessWidget {
  const BluetoothMouseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Mouse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFF4ECDC4),
          surface: const Color(0xFF1A1F3A),
          background: const Color(0xFF0A0E27),
        ),
        cardTheme: CardTheme(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: const Color(0xFF1A1F3A),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 5,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      home: const BluetoothMouseHome(),
    );
  }
}

class BluetoothMouseHome extends StatefulWidget {
  const BluetoothMouseHome({Key? key}) : super(key: key);

  @override
  State<BluetoothMouseHome> createState() => _BluetoothMouseHomeState();
}

class _BluetoothMouseHomeState extends State<BluetoothMouseHome> with TickerProviderStateMixin {
  static const platform = MethodChannel('com.example.my_mouse/hid');
  
  bool _isConnected = false;
  String _status = 'Not Connected';
  double _sensitivity = 1.5;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _checkHIDStatus();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _checkHIDStatus() async {
    try {
      final bool isRunning = await platform.invokeMethod('isHIDServiceRunning');
      setState(() {
        _isConnected = isRunning;
        _status = isRunning ? 'Connected & Ready' : 'Disconnected';
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = 'Error: ${e.message}';
      });
    }
  }

  Future<void> _startHIDService() async {
    try {
      final bool success = await platform.invokeMethod('startHIDService');
      setState(() {
        _isConnected = success;
        _status = success ? 'Connected & Ready' : 'Failed to connect';
      });
      
      if (success) {
        _showPairingInstructions();
      }
    } on PlatformException catch (e) {
      setState(() {
        _status = 'Error: ${e.message}';
      });
    }
  }

  Future<void> _stopHIDService() async {
    try {
      await platform.invokeMethod('stopHIDService');
      setState(() {
        _isConnected = false;
        _status = 'Disconnected';
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = 'Error: ${e.message}';
      });
    }
  }

  Future<void> _sendMouseMove(int dx, int dy) async {
    if (!_isConnected) return;
    try {
      await platform.invokeMethod('sendMouseMove', {'dx': dx, 'dy': dy});
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _sendMouseClick(String clickType) async {
    if (!_isConnected) return;
    try {
      await platform.invokeMethod('sendMouseClick', {'type': clickType});
      HapticFeedback.lightImpact();
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _sendDoubleClick() async {
    await _sendMouseClick('left');
    await Future.delayed(const Duration(milliseconds: 50));
    await _sendMouseClick('left');
  }

  Future<void> _sendScroll(int amount) async {
    if (!_isConnected) return;
    try {
      await platform.invokeMethod('sendScroll', {'amount': amount});
      HapticFeedback.selectionClick();
    } catch (e) {
      print('Error: $e');
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    int dx = (details.delta.dx * _sensitivity).round();
    int dy = (details.delta.dy * _sensitivity).round();
    _sendMouseMove(dx, dy);
  }

  void _showPairingInstructions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF1A1F3A),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bluetooth, size: 48, color: Color(0xFF6C63FF)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pairing Instructions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E27),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '1. Open Bluetooth settings on your PC',
                      style: TextStyle(fontSize: 15),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '2. Click "Add device" or "Add Bluetooth device"',
                      style: TextStyle(fontSize: 15),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '3. Select your phone from the list',
                      style: TextStyle(fontSize: 15),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '4. Click pair and start controlling!',
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Got it!', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0E27),
              const Color(0xFF1A1F3A),
              const Color(0xFF0A0E27),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isConnected ? _buildConnectedView() : _buildDisconnectedView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bluetooth Mouse',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isConnected ? const Color(0xFF4ECDC4) : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _status,
                    style: TextStyle(
                      fontSize: 14,
                      color: _isConnected ? const Color(0xFF4ECDC4) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isConnected 
                      ? const Color(0xFF4ECDC4).withOpacity(0.2 + _pulseController.value * 0.1)
                      : Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: _isConnected ? const Color(0xFF4ECDC4) : Colors.grey,
                  size: 32,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6C63FF),
                          const Color(0xFF4ECDC4),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A1F3A),
                        ),
                        child: const Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            const Text(
              'Ready to Connect',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Turn your phone into a wireless mouse\nfor your computer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white60,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _startHIDService,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.bluetooth_searching, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Start Connection',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSensitivityControl(),
            const SizedBox(height: 20),
            _buildTouchpad(),
            const SizedBox(height: 20),
            _buildControlButtons(),
            const SizedBox(height: 20),
            _buildDisconnectButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSensitivityControl() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.speed, color: Color(0xFF6C63FF)),
                    SizedBox(width: 12),
                    Text(
                      'Sensitivity',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _sensitivity.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF6C63FF),
                inactiveTrackColor: const Color(0xFF6C63FF).withOpacity(0.2),
                thumbColor: const Color(0xFF6C63FF),
                overlayColor: const Color(0xFF6C63FF).withOpacity(0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Slider(
                value: _sensitivity,
                min: 0.5,
                max: 3.0,
                divisions: 10,
                onChanged: (value) {
                  setState(() {
                    _sensitivity = value;
                  });
                  HapticFeedback.selectionClick();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTouchpad() {
    return Card(
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1F3A),
              const Color(0xFF0A0E27),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),
            GestureDetector(
              onPanUpdate: _handlePanUpdate,
              onTap: () => _sendMouseClick('left'),
              onDoubleTap: _sendDoubleClick,
              onLongPress: () => _sendMouseClick('right'),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.touch_app,
                          size: 48,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Touchpad',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Swipe to move • Tap to click\nLong press for right click',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildButton('Left Click', Icons.mouse, () => _sendMouseClick('left'))),
            const SizedBox(width: 12),
            Expanded(child: _buildButton('Right Click', Icons.mouse, () => _sendMouseClick('right'))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildButton('Scroll Up', Icons.arrow_upward, () => _sendScroll(3))),
            const SizedBox(width: 12),
            Expanded(child: _buildButton('Scroll Down', Icons.arrow_downward, () => _sendScroll(-3))),
          ],
        ),
      ],
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onPressed) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF4ECDC4), size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisconnectButton() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _stopHIDService,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.2),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red.withOpacity(0.5)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.power_settings_new, color: Colors.red),
              SizedBox(width: 12),
              Text(
                'Disconnect',
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Developed by Shahzad Ahmad',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white38,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 30.0;
    
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}