import 'dart:async';

import 'package:advanced_root_detection/advanced_root_detection.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advance Root Detection',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const ExampleHomeScreen(),
    );
  }
}

class ExampleHomeScreen extends StatelessWidget {
  const ExampleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Root Detection Example'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.indigo),
              const SizedBox(height: 24),
              const Text(
                'How would you like to test the package?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                icon: const Icon(Icons.analytics),
                label: const Text('Manual Testing Dashboard'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SecurityDashboard()),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.lock),
                label: const Text('Protected Real App Example'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RootDetectionGuard(
                        bypassInDebugMode: true,
                        blockedMessage: 'This app cannot run on a rooted device.',
                        // This demonstrates how a real app wraps its core UI
                        child: const ProtectedRealApp(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProtectedRealApp extends StatelessWidget {
  const ProtectedRealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Secure App'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
            SizedBox(height: 24),
            Text(
              'Secure Environment\nApp is running normally.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'If you are seeing this, the RootDetectionGuard\npassed all security checks!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  final _shield = AdvanceRootDetection();
  StreamSubscription<Threat>? _monitorSub;

  ThreatReport? _report;
  bool _checking = false;
  bool _monitoring = false;
  final List<Threat> _liveThreats = [];

  @override
  void initState() {
    super.initState();
    _runCheck();
  }

  @override
  void dispose() {
    _monitorSub?.cancel();
    _shield.stopMonitoring();
    super.dispose();
  }

  Future<void> _runCheck() async {
    setState(() {
      _checking = true;
      _report = null;
    });
    try {
      final report = await _shield.performCheck(SecurityConfig(
        android: const AndroidConfig(
          allowedInstallers: [AppStore.googlePlay, AppStore.amazonAppstore],
        ),
        ios: const IOSConfig(),
      ));
      setState(() => _report = report);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _checking = false);
    }
  }

  Future<void> _toggleMonitoring() async {
    if (_monitoring) {
      await _shield.stopMonitoring();
      await _monitorSub?.cancel();
      setState(() {
        _monitoring = false;
        _liveThreats.clear();
      });
    } else {
      _monitorSub = _shield.threatStream.listen((threat) {
        setState(() => _liveThreats.insert(0, threat));
      });
      await _shield.startMonitoring(
        const SecurityConfig(monitoringInterval: Duration(seconds: 15)),
      );
      setState(() => _monitoring = true);
    }
  }

  Future<void> _verifySensitiveOp() async {
    final safe = await _shield.verifyBeforeSensitiveOp();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(safe ? 'Safe to proceed' : 'Threat detected'),
        content: Text(
          safe
              ? 'No high/critical threats detected. Operation can proceed.'
              : 'High or critical threats were found. Block the sensitive operation.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advance Root Detection'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checking ? null : _runCheck,
            tooltip: 'Run full check',
          ),
        ],
      ),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Overall status card ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _StatusCard(report: report),
                  ),
                ),

                // ── Category grid ──────────────────────────────────────────
                if (report != null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      delegate: SliverChildListDelegate([
                        _CategoryTile(
                          label: 'Root / Jailbreak',
                          icon: Icons.security,
                          threat: report.isPrivilegedAccess,
                        ),
                        _CategoryTile(
                          label: 'Runtime Manipulation',
                          icon: Icons.bug_report,
                          threat: report.isRuntimeManipulated,
                        ),
                        _CategoryTile(
                          label: 'Debugger',
                          icon: Icons.code,
                          threat: report.isDebuggerAttached,
                        ),
                        _CategoryTile(
                          label: 'Emulator / Simulator',
                          icon: Icons.computer,
                          threat: report.isAnalysisEnvironment,
                        ),
                        _CategoryTile(
                          label: 'Integrity',
                          icon: Icons.verified_user,
                          threat: report.isIntegrityViolated,
                        ),
                        _CategoryTile(
                          label: 'Overall',
                          icon: Icons.shield,
                          threat: report.hasCriticalThreat,
                        ),
                      ]),
                    ),
                  ),

                // ── Threat list ────────────────────────────────────────────
                if (report != null && report.detectedThreats.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text('Detected Threats',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final threat = report.detectedThreats[index];
                        return _ThreatTile(threat: threat);
                      },
                      childCount: report.detectedThreats.length,
                    ),
                  ),
                ],

                // ── Live monitoring events ─────────────────────────────────
                if (_liveThreats.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text('Live Monitoring Events',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ThreatTile(threat: _liveThreats[index]),
                      childCount: _liveThreats.length,
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

      // ── FABs ──────────────────────────────────────────────────────────────
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'verify',
            onPressed: _verifySensitiveOp,
            tooltip: 'Verify before sensitive op',
            child: const Icon(Icons.lock_clock),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'monitor',
            onPressed: _toggleMonitoring,
            icon: Icon(_monitoring ? Icons.stop : Icons.sensors),
            label: Text(_monitoring ? 'Stop Monitoring' : 'Start Monitoring'),
            backgroundColor: _monitoring ? Colors.red.shade700 : null,
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final ThreatReport? report;
  const _StatusCard({required this.report});

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: const [
            Icon(Icons.hourglass_empty, size: 32),
            SizedBox(width: 16),
            Text('No check run yet. Pull to refresh.'),
          ]),
        ),
      );
    }

    final clean = report!.isClean;
    return Card(
      color: clean ? Colors.green.shade700 : Colors.red.shade700,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              clean ? Icons.check_circle : Icons.warning_amber_rounded,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clean ? 'Device is clean' : 'Threats detected',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    clean
                        ? 'No security issues found.'
                        : '${report!.detectedThreats.length} threat(s) found.',
                    style: const TextStyle(color: Colors.white70),
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

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool threat;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.threat,
  });

  @override
  Widget build(BuildContext context) {
    final color = threat ? Colors.red.shade700 : Colors.green.shade700;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              threat ? 'DETECTED' : 'CLEAN',
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreatTile extends StatelessWidget {
  final Threat threat;
  const _ThreatTile({required this.threat});

  Color get _severityColor {
    switch (threat.severity) {
      case Severity.critical:
        return Colors.red.shade700;
      case Severity.high:
        return Colors.orange.shade700;
      case Severity.medium:
        return Colors.amber.shade700;
      case Severity.low:
        return Colors.blue.shade700;
      case Severity.info:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _severityColor,
            radius: 16,
            child: Text(
              threat.severity.name[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(threat.description, style: const TextStyle(fontSize: 13)),
          subtitle: Text(threat.category.name,
              style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
        ),
      ),
    );
  }
}
