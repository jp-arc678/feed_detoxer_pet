import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:usage_stats/usage_stats.dart';

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
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const UsageTestScreen(),
    );
  }
}

class UsageTestScreen extends StatefulWidget {
  const UsageTestScreen({super.key});

  @override
  State<UsageTestScreen> createState() => _UsageTestScreenState();
}

class _UsageTestScreenState extends State<UsageTestScreen> {
  List<Map<String, dynamic>> _appUsageList = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadData();
  }

  Future<void> _checkPermissionAndLoadData() async {
    bool? isGranted = await UsageStats.checkUsagePermission();
    if (isGranted == true) {
      setState(() => _hasPermission = true);
      await _fetchUsageData();
    } else {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUsageData() async {
    setState(() => _isLoading = true);

    DateTime now = DateTime.now();
    DateTime midnight = DateTime(now.year, now.month, now.day);

    // 1. ดึงข้อมูลสถิติเวลาการใช้งานจาก Android
    List<UsageInfo> usageStats = await UsageStats.queryUsageStats(midnight, now);
    
    Map<String, int> usageMap = {};
    for (var info in usageStats) {
      int timeInForeground = int.parse(info.totalTimeInForeground ?? '0');
      if (timeInForeground > 0) {
        usageMap[info.packageName!] = (usageMap[info.packageName!] ?? 0) + timeInForeground;
      }
    }

    // 2. ดึงรายชื่อแอปทั้งหมดด้วยแพ็กเกจใหม่ (installed_apps)
    // Parameter: (excludeSystemApps: true, withIcon: true)
    List<AppInfo> installedApps = await InstalledApps.getInstalledApps();

    // 3. นำรายชื่อแอปมาผูกเข้ากับเวลา
    List<Map<String, dynamic>> combinedList = [];
    for (var app in installedApps) {
      // app.packageName จะเป็นค่าของแพ็กเกจเนม
      int msSpent = usageMap[app.packageName] ?? 0;
      
      if (msSpent > 0) {
        combinedList.add({
          'app': app,
          'duration': Duration(milliseconds: msSpent),
        });
      }
    }

    // เรียงจากมากไปน้อย
    combinedList.sort((a, b) => (b['duration'] as Duration).compareTo(a['duration'] as Duration));

    setState(() {
      _appUsageList = combinedList;
      _isLoading = false;
    });
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours ชม. $minutes นาที';
    } else if (minutes > 0) {
      return '$minutes นาที $seconds วินาที';
    } else {
      return '$seconds วินาที';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทดสอบระบบดึงข้อมูลแอป'),
        actions: [
          if (_hasPermission)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchUsageData,
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
              ? _buildPermissionPrompt()
              : _appUsageList.isEmpty
                  ? const Center(child: Text('วันนี้ยังไม่มีบันทึกข้อมูลการใช้งานแอปใดเลย'))
                  : ListView.builder(
                      itemCount: _appUsageList.length,
                      itemBuilder: (context, index) {
                        final item = _appUsageList[index];
                        final AppInfo app = item['app'] as AppInfo;
                        final Duration duration = item['duration'] as Duration;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            // เช็คว่าถ้ามีไอคอนให้แสดง ถ้าไม่มีให้ใส่ไอคอนแอนดรอยด์แทน
                            leading: app.icon != null 
                                ? Image.memory(app.icon!, width: 40, height: 40) 
                                : const Icon(Icons.android, size: 40),
                            title: Text(app.name , style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(app.packageName),
                            trailing: Text(
                              _formatDuration(duration),
                              style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildPermissionPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            const Text(
              'จำเป็นต้องขอสิทธิ์เข้าถึงข้อมูลการใช้งาน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'กรุณากดปุ่มด้านล่าง เพื่อเปิดสิทธิ์การเข้าถึงข้อมูลการใช้งาน (Usage Access) ให้แก่แอปพลิเคชัน',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
              onPressed: () async {
                await UsageStats.grantUsagePermission();
                _checkPermissionAndLoadData();
              },
              child: const Text('เปิดหน้าตั้งค่าระบบ', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}