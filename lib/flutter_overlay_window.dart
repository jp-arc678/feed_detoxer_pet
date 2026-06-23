import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:rive/rive.dart';

// ==================================================
// 1. ทางเข้าสำหรับหน้าต่าง Overlay (สัตว์เลี้ยงลอยบนจอ)
// ==================================================
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PetOverlayScreen(),
    ),
  );
}

class PetOverlayScreen extends StatefulWidget {
  const PetOverlayScreen({super.key});

  @override
  State<PetOverlayScreen> createState() => _PetOverlayScreenState();
}

class _PetOverlayScreenState extends State<PetOverlayScreen> {
  // ตัวแปรสำหรับควบคุม State Machine ของ Rive
  StateMachineController? _riveController;
  SMIBool? _isAngry; 

  // ฟังก์ชันนี้จะทำงานเมื่อโหลดไฟล์ Rive เสร็จ
  void _onRiveInit(Artboard artboard) {
    // โหลด State Machine ตามชื่อที่ตั้งไว้ในไฟล์
    _riveController = StateMachineController.fromArtboard(artboard, 'State Machine 1');
    
    if (_riveController != null) {
      artboard.addController(_riveController!);
      // ผูกตัวแปรในโค้ดเข้ากับตัวแปรในแอนิเมชัน (ใช้ findInput ใน 0.14.8 ได้ปกติ)
      _isAngry = _riveController!.findInput<bool>('isAngry') as SMIBool?;
    }
  }

  @override
  void dispose() {
    _riveController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // พื้นหลังต้องโปร่งใส
      elevation: 0,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 50.0, right: 16.0),
          child: GestureDetector(
            // เพิ่มการโต้ตอบ: เวลากดที่ตัวน้อง จะสลับอารมณ์โกรธ/ปกติ
            onTap: () {
              if (_isAngry != null) {
                _isAngry!.value = !_isAngry!.value;
                log("Pet Tapped! isAngry: ${_isAngry!.value}");
              }
            },
            child: SizedBox(
              width: 150, // กำหนดขนาดตัวน้อง
              height: 150,
              // ดึงไฟล์ Rive มาแสดงผล 
              // 🔑 เอาคำว่า const ออก และเพิ่ม onInit เข้าไป
              child: RiveAnimation.network(
                'https://cdn.rive.app/animations/vehicles.riv', 
                fit: BoxFit.contain,
                onInit: _onRiveInit, // 👈 ถ้าขาดบรรทัดนี้ โค้ดจะไม่รู้ว่าต้องไปคุมแอนิเมชันยังไง
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================
// 2. ทางเข้าสำหรับแอปหลักหน้าบ้าน (Control Panel)
// ==================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isPetActive = false;

  Future<void> _togglePetOverlay(bool turnOn) async {
    bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!isGranted) {
      await FlutterOverlayWindow.requestPermission();
      return;
    }

    if (turnOn) {
      // ใช้ defaultFlag เพื่อให้รับการสัมผัส (จิ้มน้องได้)
      await FlutterOverlayWindow.showOverlay(
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
        flag: OverlayFlag.defaultFlag, 
        alignment: OverlayAlignment.center,
        visibility: NotificationVisibility.visibilitySecret,
      );
    } else {
      await FlutterOverlayWindow.closeOverlay();
    }

    setState(() {
      _isPetActive = turnOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Pet Detox')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 100, color: Colors.teal),
            const SizedBox(height: 20),
            const Text('ให้เพื่อนตัวน้อยช่วยดูแลเวลาของคุณ'),
            const SizedBox(height: 40),
            SwitchListTile(
              title: const Text('เรียกน้องออกมาบนหน้าจอ', style: TextStyle(fontWeight: FontWeight.bold)),
              value: _isPetActive,
              activeColor: Colors.teal,
              onChanged: _togglePetOverlay,
            ),
          ],
        ),
      ),
    );
  }
}