import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/app_layout.dart';

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
  late TextEditingController _phoneCtrl;
  late TextEditingController _locationCtrl;

  @override
  void initState() {
    super.initState();
    // mock initial values — replace with Provider/Firebase values when integrating
    _nameCtrl = TextEditingController(text: 'user');
    _emailCtrl = TextEditingController(text: 'user@gmail.com');
    _phoneCtrl = TextEditingController(text: '+91 123467890');
    _locationCtrl = TextEditingController(text: 'thrissur,kerala');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Widget _roleBadge(RoleType role) {
    Color bg;
    Color fg;
    IconData icon;
    switch (role) {
      case RoleType.admin:
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

  List<Map<String, String>> _buildStats(RoleType role) {
    if (role == RoleType.volunteer) {
      return [
        {'label': 'Tasks Completed', 'value': '23'},
        {'label': 'Hours Volunteered', 'value': '47'},
        {'label': 'Rating', 'value': '4.8 ⭐'},
      ];
    }
    return [
      {'label': 'Requests Made', 'value': '5'},
      {'label': 'Completed', 'value': '4'},
      {'label': 'Active', 'value': '1'},
    ];
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
        return const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        );
    }
  }

  Future<void> _openEditDialog() async {
    final nameCtrl = TextEditingController(text: _nameCtrl.text);
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    final phoneCtrl = TextEditingController(text: _phoneCtrl.text);
    final locationCtrl = TextEditingController(text: _locationCtrl.text);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _nameCtrl.text = nameCtrl.text;
                            _emailCtrl.text = emailCtrl.text;
                            _phoneCtrl.text = phoneCtrl.text;
                            _locationCtrl.text = locationCtrl.text;
                            Navigator.of(ctx).pop(true);
                          },
                          child: const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == true) {
      setState(() {});
      // persist via Provider/Firebase when integrated
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _buildStats(widget.role);
    final headerGrad = _headerGradient(widget.role);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with gradient and large padding
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: headerGrad,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
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
                    'Manage your account settings',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),

            // Overlapping card + content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AppLayout(
                  padding: EdgeInsets.zero,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    children: [
                      // Profile card (overlaps header visually)
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
                                // Avatar + name + role badge
                                Column(
                                  children: [
                                    Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(48),
                                        gradient: headerGrad,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 6,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          _nameCtrl.text
                                              .split(' ')
                                              .map(
                                                (s) => s.isNotEmpty ? s[0] : '',
                                              )
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

                                const SizedBox(height: 12),

                                // Contact / location blocks
                                Column(
                                  children: [
                                    _infoRow(
                                      icon: Icons.email,
                                      title: 'Email',
                                      value: _emailCtrl.text,
                                    ),
                                    const SizedBox(height: 8),
                                    _infoRow(
                                      icon: Icons.phone,
                                      title: 'Phone',
                                      value: _phoneCtrl.text,
                                    ),
                                    const SizedBox(height: 8),
                                    _infoRow(
                                      icon: Icons.place,
                                      title: 'Location',
                                      value: _locationCtrl.text,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Stats grid
                      Row(
                        children: stats.map((s) {
                          final idx = stats.indexOf(s);
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: idx == stats.length - 1 ? 0 : 8,
                              ),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        s['value']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        s['label']!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),

                      // Actions: Edit & Logout
                      Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _openEditDialog,
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                          const SizedBox(height: 10),
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

                      const SizedBox(height: 14),

                      // Volunteer extra info
                      if (widget.role == RoleType.volunteer)
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  color: Colors.green.shade700,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Verified Volunteer',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF166534),
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'You\'re making a real difference in your community. Thank you for your service!',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 36),
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
