import 'package:flutter/material.dart';

class CampAdminDashboard extends StatefulWidget {
  final VoidCallback onNavigateToProfile;

  const CampAdminDashboard({super.key, required this.onNavigateToProfile});

  @override
  State<CampAdminDashboard> createState() => _CampAdminDashboardState();
}

class _CampAdminDashboardState extends State<CampAdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final greenStart = const Color(0xFF059669);
    final greenEnd = const Color(0xFF047857);

    return Scaffold(
      body: Column(
        children: [
          // ================= HEADER =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [greenStart, greenEnd]),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Camp Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Manage camp operations',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          // ================= TABS =================
          TabBar(
            controller: _tabController,
            labelColor: greenStart,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Residents'),
              Tab(text: 'Supplies'),
              Tab(text: 'Emergencies'),
            ],
          ),

          // ================= TAB CONTENT =================
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _simpleCard('Camp Residents'),
                _simpleCard('Camp Supplies'),
                _simpleCard('Emergency Requests'),
              ],
            ),
          ),
        ],
      ),

      // ================= BOTTOM NAV =================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavButton(
              icon: Icons.home,
              label: 'Dashboard',
              active: true,
              onTap: () {},
            ),
            _NavButton(
              icon: Icons.settings,
              label: 'Profile',
              active: false,
              onTap: widget.onNavigateToProfile,
            ),
          ],
        ),
      ),
    );
  }

  // ================= SIMPLE CARD =================
  Widget _simpleCard(String title) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(title, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

// ================= NAV BUTTON =================
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).primaryColor
        : Colors.grey.shade400;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
