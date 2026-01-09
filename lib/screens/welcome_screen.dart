// lib/src/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:relief/app_state.dart';
import 'package:relief/widgets/app_layout.dart';

/// Public welcome screen shown after splash.
/// This screen ONLY navigates forward.
/// Role selection happens in RoleSelectionScreen.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Widget _roleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).cardColor,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
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
                'How would you like to get started today?',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),

              /// ROLE CARDS
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
                      onTap: () =>
                          context.read<AppState>().handleNavigateToRegister(),
                    ),
                    const SizedBox(height: 12),
                    _roleCard(
                      context: context,
                      icon: Icons.volunteer_activism,
                      title: 'I Want to Donate',
                      subtitle: 'Provide aid and resources',
                      gradient: [primary, const Color(0xFF0056B3)],
                      onTap: () =>
                          context.read<AppState>().handleNavigateToRegister(),
                    ),
                    const SizedBox(height: 12),
                    _roleCard(
                      context: context,
                      icon: Icons.group,
                      title: 'I Want to Volunteer',
                      subtitle: 'Help distribute aid on the ground',
                      gradient: [Colors.green.shade500, Colors.green.shade600],
                      onTap: () =>
                          context.read<AppState>().handleNavigateToRegister(),
                    ),
                    const SizedBox(height: 12),
                    _roleCard(
                      context: context,
                      icon: Icons.shield,
                      title: 'Admin Access',
                      subtitle: 'Sign in as Admin or Camp Admin',
                      gradient: [
                        Colors.purple.shade500,
                        Colors.purple.shade600,
                      ],
                      onTap: () =>
                          context.read<AppState>().handleNavigateToRegister(),
                    ),
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
