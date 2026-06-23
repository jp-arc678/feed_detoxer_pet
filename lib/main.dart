import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:usage_stats/usage_stats.dart';

import 'core/theme.dart';
import 'data/database.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/permissions_screen.dart';
import 'features/targets/target_list_screen.dart';
import 'features/pet_settings/pet_settings_screen.dart';
import 'services/usage/brain_channel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDatabase();
  await BrainChannel.setTargetApps(['com.android.chrome']); // test target
  await BrainChannel.start();
  runApp(const ProviderScope(child: FeedDetoxerApp()));
}

class FeedDetoxerApp extends StatelessWidget {
  const FeedDetoxerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feed Detoxer',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const _StartupRouter(),
    );
  }
}

// Checks required permissions once on cold start and routes accordingly.
class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final usageOk = await UsageStats.checkUsagePermission() ?? false;
    final overlayOk = await FlutterOverlayWindow.isPermissionGranted();
    final destination =
        (usageOk && overlayOk) ? const MainShell() : const PermissionsScreen();
    if (mounted) setState(() => _destination = destination);
  }

  @override
  Widget build(BuildContext context) {
    return _destination ??
        const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    TargetListScreen(),
    PetSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'Targets',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Pet',
          ),
        ],
      ),
    );
  }
}
