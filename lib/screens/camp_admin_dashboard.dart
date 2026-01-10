import 'package:relief/services/api_service.dart';

class CampAdminDashboard extends StatefulWidget {
  final VoidCallback onNavigateToProfile;

  const CampAdminDashboard({super.key, required this.onNavigateToProfile});

  @override
  State<CampAdminDashboard> createState() => _CampAdminDashboardState();
}

class _CampAdminDashboardState extends State<CampAdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getCampAdminDashboard();
      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _dashboardData = result['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['error'] ?? 'Failed to load camp data';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final campInfo = _dashboardData?['camp'] ?? {};
    final residents = _dashboardData?['residents'] ?? {};
    final resources = _dashboardData?['resources'] ?? {};

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campInfo['name'] ?? 'Camp Admin Panel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${campInfo['type']?.toString().toUpperCase() ?? "MANAGEMENT"} | ${campInfo['status'] ?? "Active"}',
                  style: const TextStyle(color: Colors.white70),
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
              Tab(text: 'Stats'),
              Tab(text: 'Supplies'),
              Tab(text: 'Residents'),
            ],
          ),

          // ================= TAB CONTENT =================
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _statsView(residents, resources),
                _simpleCard('Supplies: ${resources['total'] ?? 0} active items'),
                _simpleCard('Residents: ${residents['total'] ?? 0} total'),
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

  // ================= STATS VIEW =================
  Widget _statsView(Map residents, Map resources) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _statCard('Total Residents', '${residents['total']}', Icons.person, Colors.blue),
        _statCard('High Priority', '${residents['high_priority']}', Icons.warning, Colors.orange),
        _statCard('Active Supplies', '${resources['total']}', Icons.category, Colors.green),
        _statCard('Pending Requests', '${resources['requests']}', Icons.assignment, Colors.red),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
