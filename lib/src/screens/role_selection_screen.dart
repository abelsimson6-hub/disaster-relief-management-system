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
  // used to trigger staggered animations
  final List<bool> _visible = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    // staggered show
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
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
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

    // Slide + Fade using AnimatedOpacity + AnimatedSlide
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: visible ? 1 : 0,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 400),
        offset: visible ? Offset.zero : const Offset(-0.06, 0),
        curve: Curves.easeOut,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: card,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF007BFF);

    final roles = [
      {
        'id': RoleType.victim,
        'title': 'I Need Help',
        'subtitle': 'Request emergency assistance',
        'icon': Icons.favorite,
        'gradient': [Colors.red.shade400, Colors.red.shade300],
      },
      {
        'id': RoleType.donor,
        'title': 'I Want to Donate',
        'subtitle': 'Provide aid and resources',
        'icon': Icons.volunteer_activism,
        'gradient': [primary, const Color(0xFF0056B3)],
      },
      {
        'id': RoleType.volunteer,
        'title': 'I Want to Volunteer',
        'subtitle': 'Help distribute aid',
        'icon': Icons.group,
        'gradient': [Colors.green.shade500, Colors.green.shade600],
      },
      {
        'id': RoleType.admin,
        'title': 'Admin Access',
        'subtitle': 'Manage and coordinate',
        'icon': Icons.shield,
        'gradient': [Colors.purple.shade500, Colors.purple.shade600],
      },
    ];

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
                child: ListView.separated(
                  itemCount: roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemBuilder: (context, index) {
                    final r = roles[index];
                    return _roleCard(
                      context: context,
                      icon: r['icon'] as IconData,
                      title: r['title'] as String,
                      subtitle: r['subtitle'] as String,
                      gradient: (r['gradient'] as List<Color>),
                      visible: _visible[index],
                      onTap: () => widget.onSelectRole(r['id'] as RoleType),
                    );
                  },
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
