import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:usage_stats/usage_stats.dart';

import '../../main.dart';
import '../../services/usage/brain_channel.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _usageGranted = false;
  bool _overlayGranted = false;
  bool _notifGranted = false;
  bool _batteryGranted = false;
  bool _isMiui = false;

  bool get _requiredGranted => _usageGranted && _overlayGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check every time the user returns from Android settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final usage = await UsageStats.checkUsagePermission() ?? false;
    final overlay = await FlutterOverlayWindow.isPermissionGranted();
    final notif = await Permission.notification.isGranted;
    final battery = await Permission.ignoreBatteryOptimizations.isGranted;
    final manufacturer = await BrainChannel.getManufacturer();
    final isMiui = manufacturer.contains('xiaomi') ||
        manufacturer.contains('redmi') ||
        manufacturer.contains('poco');

    if (!mounted) return;
    setState(() {
      _usageGranted = usage;
      _overlayGranted = overlay;
      _notifGranted = notif;
      _batteryGranted = battery;
      _isMiui = isMiui;
    });
  }

  void _proceedToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Setup'),
        backgroundColor: colorScheme.surface,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '🐾',
                      style: const TextStyle(fontSize: 56),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Feed Detoxer needs a few permissions to keep watch for you.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Required permissions
                  _SectionLabel(label: 'Required'),
                  const SizedBox(height: 8),
                  _PermissionTile(
                    icon: Icons.bar_chart,
                    title: 'Usage Access',
                    description:
                        'Lets the app see how long you spend in each app so the pet can react.',
                    isGranted: _usageGranted,
                    isRequired: true,
                    onTap: () async {
                      await UsageStats.grantUsagePermission();
                    },
                  ),
                  const SizedBox(height: 10),
                  _PermissionTile(
                    icon: Icons.picture_in_picture_alt,
                    title: 'Draw over other apps',
                    description:
                        'Allows the pet overlay to appear on top of the app you\'re using.',
                    isGranted: _overlayGranted,
                    isRequired: true,
                    onTap: () async {
                      await FlutterOverlayWindow.requestPermission();
                    },
                  ),
                  const SizedBox(height: 24),

                  // Recommended permissions
                  _SectionLabel(label: 'Recommended'),
                  const SizedBox(height: 8),
                  _PermissionTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    description:
                        'Lets the pet send you a nudge when it has something to say (Android 13+).',
                    isGranted: _notifGranted,
                    isRequired: false,
                    onTap: () async {
                      await Permission.notification.request();
                      _refresh();
                    },
                  ),
                  const SizedBox(height: 10),
                  _PermissionTile(
                    icon: Icons.battery_saver_outlined,
                    title: 'Battery optimization exemption',
                    description:
                        'Prevents Android from killing the background service that times your sessions.',
                    isGranted: _batteryGranted,
                    isRequired: false,
                    onTap: () async {
                      await Permission.ignoreBatteryOptimizations.request();
                      _refresh();
                    },
                  ),
                  if (_isMiui) ...[
                    const SizedBox(height: 10),
                    _PermissionTile(
                      icon: Icons.security_outlined,
                      title: 'MIUI Auto-start',
                      description:
                          'On Xiaomi / MIUI, auto-start must be enabled separately in Security settings. '
                          'Without it, the background monitor stops when the screen turns off. '
                          "Grant cannot be checked automatically — if the pet stops appearing, open this.",
                      isGranted: false,
                      isRequired: false,
                      onTap: () => BrainChannel.openMiuiAutoStart(),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  if (!_requiredGranted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Grant the two required permissions above to continue.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _requiredGranted ? _proceedToApp : null,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text("Let's go!"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final bool isRequired;
  final VoidCallback onTap;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.isRequired,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isGranted
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isGranted
                    ? colorScheme.secondary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Status chip
                      _StatusChip(granted: isGranted),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (!isGranted) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: onTap,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Open Settings'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool granted;
  const _StatusChip({required this.granted});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: granted ? colorScheme.secondaryContainer : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        granted ? 'Granted' : 'Needed',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: granted ? colorScheme.onSecondaryContainer : colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
