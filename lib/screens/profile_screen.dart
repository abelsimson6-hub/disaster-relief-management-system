import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/app_layout.dart';
import '../services/api_service.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final RoleType role;

  const ProfileScreen({
    super.key,
    required this.onBack,
    required this.onLogout,
    required this.role,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;

  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.fetchProfile();

      _nameCtrl.text = profile.username;
      _emailCtrl.text = profile.email;

      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ---------------- UI helpers ----------------

  Widget _roleBadge(RoleType role) {
    Color bg;
    Color fg;
    IconData icon;

    switch (role) {
      case RoleType.admin:
      case RoleType.campAdmin:
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade700;
        icon = Icons.shield;
        break;
      case RoleType.volunteer:
        bg = Colors.green.shade100;
        fg = Colors.green.shade700;
        icon = Icons.emoji_events;
        break;
      case RoleType.donor:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade700;
        icon = Icons.person;
        break;
      case RoleType.victim:
        bg = Colors.red.shade100;
        fg = Colors.red.shade700;
        icon = Icons.person;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            role.name[0].toUpperCase() + role.name.substring(1),
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _headerGradient(RoleType role) {
    switch (role) {
      case RoleType.victim:
        return const LinearGradient(
          colors: [Color(0xFFFF4B4B), Color(0xFFFF6B6B)],
        );
      case RoleType.donor:
        return const LinearGradient(
          colors: [Color(0xFF007BFF), Color(0xFF0056B3)],
        );
      case RoleType.volunteer:
        return const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF059669)],
        );
      case RoleType.admin:
      case RoleType.campAdmin:
        return const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        );
    }
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text(_error!)),
      );
    }

    final headerGrad = _headerGradient(widget.role);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: headerGrad,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'My Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Account information',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AppLayout(
                  padding: EdgeInsets.zero,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -40),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Avatar + name
                                Column(
                                  children: [
                                    Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(48),
                                        gradient: headerGrad,
                                      ),
                                      child: Center(
                                        child: Text(
                                          _nameCtrl.text
                                              .split(' ')
                                              .map((s) => s.isNotEmpty ? s[0] : '')
                                              .take(2)
                                              .join(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _nameCtrl.text,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _roleBadge(widget.role),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                _infoRow(
                                  icon: Icons.email,
                                  title: 'Email',
                                  value: _emailCtrl.text,
                                ),

                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      OutlinedButton.icon(
                        onPressed: widget.onLogout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade200),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF007BFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
