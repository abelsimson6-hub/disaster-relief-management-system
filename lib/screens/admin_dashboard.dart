// lib/src/screens/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:relief/services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  final VoidCallback onNavigateToProfile;
  const AdminDashboard({super.key, required this.onNavigateToProfile});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Map<String, dynamic>> stats = [];
  List<Map<String, String>> users = [];
  List<Map<String, dynamic>> volunteers = [];
  bool _isLoading = true;
  String? _errorMessage;

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
      final dashboardResult = await ApiService.getAdminDashboard();
      final usersResult = await ApiService.getUsers();
      final volunteersResult = await ApiService.getVolunteersList();

      if (mounted) {
        if (dashboardResult['success'] == true) {
          final data = dashboardResult['data'];
          
          List<Map<String, String>> fetchedUsers = [];
          if (usersResult['success'] == true) {
            final userData = usersResult['data']['users'] as List;
            fetchedUsers = userData.map((u) => {
              'name': u['username'].toString(),
              'email': u['email'].toString(),
              'status': u['is_active'] == true ? 'active' : 'inactive',
            }).toList();
          }

          List<Map<String, dynamic>> fetchedVolunteers = [];
          if (volunteersResult['success'] == true) {
            final volunteerData = volunteersResult['data']['volunteers'] as List;
            fetchedVolunteers = volunteerData.map((v) => {
              'name': v['username'].toString(),
              'tasks': '0', // Could be expanded
              'rating': '5.0',
              'verified': true,
            }).toList();
          }

          setState(() {
            stats = [
              {
                'label': 'Total Users',
                'value': '${data['users']?['total'] ?? 0}',
                'icon': Icons.people,
                'colors': [Color(0xFF3B82F6), Color(0xFF2563EB)]
              },
              {
                'label': 'Volunteers',
                'value': '${data['users']?['volunteers'] ?? 0}',
                'icon': Icons.verified_user,
                'colors': [Color(0xFF34D399), Color(0xFF10B981)]
              },
              {
                'label': 'Pending Requests',
                'value': '${data['sos_requests']?['pending'] ?? 0}',
                'icon': Icons.description,
                'colors': [Color(0xFFF59E0B), Color(0xFFFBBF24)]
              },
              {
                'label': 'Completed',
                'value': '${data['sos_requests']?['resolved'] ?? 0}',
                'icon': Icons.trending_up,
                'colors': [Color(0xFF8B5CF6), Color(0xFF7C3AED)]
              },
            ];
            users = fetchedUsers;
            volunteers = fetchedVolunteers;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = dashboardResult['error'] ?? 'Failed to load dashboard data';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading data: ${e.toString()}';
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

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green.shade700;
      case 'inactive':
        return Colors.grey.shade700;
      default:
        return Colors.orange.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final purpleStart = const Color(0xFF7C3AED);
    final purpleEnd = const Color(0xFF6D28D9);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [purpleStart, purpleEnd]),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Text('Admin Control Center', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    Text('Manage relief operations', style: TextStyle(color: Colors.white70)),
                  ]),
                ),

                // Body padding
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: Column(
                    children: [
                      // Stats grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.2,
                        ),
                        itemBuilder: (context, index) {
                          final s = stats[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [s['colors'][0] as Color, s['colors'][1] as Color]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                                  child: Icon(s['icon'] as IconData, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text(s['value'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(s['label'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ]),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
                        ),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              labelColor: Theme.of(context).primaryColor,
                              unselectedLabelColor: Colors.grey.shade600,
                              indicator: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              tabs: const [
                                Tab(text: 'Users'),
                                Tab(text: 'Volunteers'),
                                Tab(text: 'Reports'),
                              ],
                            ),
                            SizedBox(
                              height: 420, // fixed height for tab content (scroll inside)
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // Users tab
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: ListView.separated(
                                      itemCount: users.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, i) {
                                        final u = users[i];
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(backgroundColor: Colors.grey.shade100, foregroundColor: Colors.black87, child: Text(u['name']!.split(' ').map((e) => e[0]).take(2).join())),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                  Text(u['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                  const SizedBox(height: 4),
                                                  Text(u['email']!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                ]),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: _statusColor(u['status']!).withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(u['status']!, style: TextStyle(color: _statusColor(u['status']!), fontSize: 12)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Volunteers tab
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: ListView.separated(
                                      itemCount: volunteers.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, i) {
                                        final v = volunteers[i];
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(children: [
                                                CircleAvatar(backgroundColor: Colors.grey.shade100, foregroundColor: Colors.black87, child: Text(v['name'].split(' ').map((e) => e[0]).take(2).join())),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                    Row(children: [
                                                      Text(v['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                                      const SizedBox(width: 8),
                                                      if (v['verified'] as bool) Icon(Icons.check_circle, color: Colors.blue.shade600, size: 16),
                                                    ]),
                                                    const SizedBox(height: 6),
                                                    Text('${v['tasks']} tasks completed • ⭐ ${v['rating']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                  ]),
                                                ),
                                              ]),
                                              const SizedBox(height: 10),
                                              if (!(v['verified'] as bool))
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      // mock verify action
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Volunteer verified (mock)')));
                                                    },
                                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                                                    child: const Text('Verify Volunteer'),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Reports tab
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: ListView(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('System Activity', style: TextStyle(fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 12),
                                              Container(
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Center(child: Icon(Icons.bar_chart, size: 40, color: Color(0xFF2563EB))),
                                              ),
                                              const SizedBox(height: 12),
                                              const Text('Activity has increased by 24% this week', style: TextStyle(color: Colors.black54)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                                                Text('Response Time', style: TextStyle(fontWeight: FontWeight.w600)),
                                                SizedBox(height: 6),
                                                Text('12 min', style: TextStyle(fontSize: 18, color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                                                SizedBox(height: 4),
                                                Text('Average response time', style: TextStyle(color: Colors.black54)),
                                              ]),
                                              const Icon(Icons.trending_up, size: 36, color: Colors.green),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavButton(icon: Icons.home, label: 'Dashboard', active: true, color: purpleStart, onTap: () {}),
            _NavButton(icon: Icons.people, label: 'Users', active: false, onTap: () {}),
            _NavButton(icon: Icons.settings, label: 'Settings', active: false, onTap: widget.onNavigateToProfile),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? color;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.label, required this.active, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: active ? activeColor : Colors.grey.shade400),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: active ? activeColor : Colors.grey.shade400)),
      ]),
    );
  }
}
