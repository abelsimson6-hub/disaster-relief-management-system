// lib/src/screens/role_selection_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/app_layout.dart';

class RoleSelectionScreen extends StatefulWidget {
  final void Function(RoleType) onSelectRole;
  const RoleSelectionScreen({super.key, required this.onSelectRole});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final List<bool> _visible = [false, false, false, false];
  bool showAdminOptions = false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _visible.length; i++) {
      Future.delayed(Duration(milliseconds: 100 * i), () {
        if (mounted) {
          setState(() => _visible[i] = true);
        }
      });
    }
  }

  Widget _roleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required bool visible,
    required VoidCallback onTap,
  }) {
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 400),
        offset: visible ? Offset.zero : const Offset(-0.06, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: card,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF007BFF);

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AppLayout(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 36,
                backgroundColor: primary,
                child: const Icon(
                  Icons.volunteer_activism,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Welcome to ReliefConnect',
                style: TextStyle(
                  color: primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'How would you like to help today?',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _roleCard(
                      context: context,
                      icon: Icons.favorite,
                      title: 'I Need Help',
                      subtitle: 'Request emergency assistance',
                      gradient: [Colors.red.shade400, Colors.red.shade300],
                      visible: _visible[0],
                      onTap: () => widget.onSelectRole(RoleType.victim),
                    ),
                    const SizedBox(height: 12),

                    _roleCard(
                      context: context,
                      icon: Icons.volunteer_activism,
                      title: 'I Want to Donate',
                      subtitle: 'Provide aid and resources',
                      gradient: [primary, const Color(0xFF0056B3)],
                      visible: _visible[1],
                      onTap: () => widget.onSelectRole(RoleType.donor),
                    ),
                    const SizedBox(height: 12),

                    _roleCard(
                      context: context,
                      icon: Icons.group,
                      title: 'I Want to Volunteer',
                      subtitle: 'Help distribute aid',
                      gradient: [Colors.green.shade500, Colors.green.shade600],
                      visible: _visible[2],
                      onTap: () => widget.onSelectRole(RoleType.volunteer),
                    ),
                    const SizedBox(height: 12),

                    _roleCard(
                      context: context,
                      icon: Icons.shield,
                      title: 'Admin Access',
                      subtitle: 'Manage and coordinate',
                      gradient: [
                        Colors.purple.shade500,
                        Colors.purple.shade600,
                      ],
                      visible: _visible[3],
                      onTap: () {
                        setState(() {
                          showAdminOptions = !showAdminOptions;
                        });
                      },
                    ),

                    if (showAdminOptions) ...[
                      const SizedBox(height: 12),

                      _roleCard(
                        context: context,
                        icon: Icons.security,
                        title: 'Admin',
                        subtitle: 'System administrator',
                        gradient: [Colors.deepPurple, Colors.deepPurpleAccent],
                        visible: true,
                        onTap: () => widget.onSelectRole(RoleType.admin),
                      ),
                      const SizedBox(height: 12),

                      _roleCard(
                        context: context,
                        icon: Icons.home_work,
                        title: 'Camp Admin',
                        subtitle: 'Manage relief camps',
                        gradient: [Colors.indigo, Colors.indigoAccent],
                        visible: true,
                        onTap: () => widget.onSelectRole(RoleType.campAdmin),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'Together we rebuild stronger',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
