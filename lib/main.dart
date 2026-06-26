import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:usage_stats/usage_stats.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'data/database.dart';
import 'data/repositories/target_app_repository.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/permissions_screen.dart';
import 'features/overlay/overlay_app.dart';
import 'features/pet_settings/pet_settings_screen.dart';
import 'features/targets/target_list_screen.dart';
import 'services/usage/brain_channel.dart';
import 'services/usage/overlay_manager.dart';
import 'services/usage/session_listener.dart';

// ─── Main app entry point ─────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDatabase();
  await TargetAppRepository().syncToBrainOnStartup();
  await BrainChannel.start();
  SessionListener.instance.start();
  OverlayManager.instance.start();
  runApp(const ProviderScope(child: FeedDetoxerApp()));
}

// ─── Overlay engine entry point ───────────────────────────────────────────────
// Called by flutter_overlay_window's OverlayService in a separate Flutter engine.
// No Hive, no Riverpod — overlay is stateless and driven by shareData() calls.

@pragma('vm:entry-point')
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

// ─── App ─────────────────────────────────────────────────────────────────────

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

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    TargetListScreen(),
    PetSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(todayAggregatesProvider);
      ref.invalidate(sessionHistoryProvider);
      ref.invalidate(bondProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.apps_outlined),
              selectedIcon: Icon(Icons.apps),
              label: 'Targets'),
          NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets),
              label: 'Pet'),
        ],
      ),
    );
  }
}
