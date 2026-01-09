// lib/src/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController;
  double _progress = 0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    // Controller for ripple animation (repeats)
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Progress timer: increase by 2 every 30ms -> ~1.5s to reach 100 (same behavior as React)
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 2;
        if (_progress >= 100) {
          _progress = 100;
          _progressTimer?.cancel();
          // Wait ~300ms then call onComplete (matches React)
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              widget.onComplete();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _rippleController.dispose();
    super.dispose();
  }

  // Helper to compute a phased value for the second ripple (half-cycle offset)
  double _phaseValue(double baseValue, double offset) {
    final v = (baseValue + offset) % 1.0;
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated ripple + logo
                SizedBox(
                  width: 180,
                  height: 180,
                  child: AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, child) {
                      final t = _rippleController.value; // 0..1
                      final t2 = _phaseValue(t, 0.5);
                      // scale and opacity calculations (similar to React arrays)
                      final scale1 = 1 + t * 1.5;
                      final opacity1 = (1 - t).clamp(0.0, 1.0);

                      final scale2 = 1 + t2 * 1.5;
                      final opacity2 = (1 - t2).clamp(0.0, 1.0);

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ripple 1
                          Opacity(
                            opacity: opacity1 * 0.5,
                            child: Transform.scale(
                              scale: scale1,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                            ),
                          ),
                          // Ripple 2
                          Opacity(
                            opacity: opacity2 * 0.45,
                            child: Transform.scale(
                              scale: scale2,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                            ),
                          ),
                          // Logo circle
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.volunteer_activism,
                              color: primary,
                              size: 56,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'ReliefConnect',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connecting Help, Hope, and Humanity',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: 280,
                  child: Column(
                    children: [
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progress / 100.0,
                          minHeight: 6,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
