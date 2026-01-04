// lib/src/screens/victim_dashboard.dart
import 'package:flutter/material.dart';
import 'package:relief/src/services/api_service.dart';

class VictimDashboard extends StatefulWidget {
  final VoidCallback onNavigateToMap;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToRequestDetails;

  const VictimDashboard({
    super.key,
    required this.onNavigateToMap,
    required this.onNavigateToProfile,
    required this.onNavigateToRequestDetails,
  });

  @override
  State<VictimDashboard> createState() => _VictimDashboardState();
}

class _VictimDashboardState extends State<VictimDashboard> {
  List<dynamic> _helpRequests = [];
  List<dynamic> _disasters = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load help requests and disasters in parallel
      final requestsResult = await ApiService.getHelpRequests();
      final disastersResult = await ApiService.getDisasters();

      if (mounted) {
        setState(() {
          if (requestsResult['success'] == true) {
            _helpRequests = requestsResult['data'] ?? [];
          }
          if (disastersResult['success'] == true) {
            _disasters = disastersResult['data'] ?? [];
          }
          _isLoading = false;
        });
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

  Future<void> _handleSOS() async {
    // Show dialog to create help request
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    int? selectedDisasterId;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send SOS Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_disasters.isNotEmpty)
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Disaster'),
                  items: _disasters.map((d) => DropdownMenuItem<int>(
                    value: d['id'] as int,
                    child: Text(d['name']?.toString() ?? 'Unknown'),
                  )).toList(),
                  onChanged: (val) => selectedDisasterId = val,
                ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedDisasterId != null && descriptionController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'disaster_id': selectedDisasterId,
                  'description': descriptionController.text,
                  'location': locationController.text.isNotEmpty ? locationController.text : 'Unknown',
                });
              }
            },
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );

    if (result != null) {
      final createResult = await ApiService.createHelpRequest(
        disasterId: result['disaster_id'] as int,
        description: result['description'] as String,
        location: result['location'] as String,
      );

      if (mounted) {
        if (createResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SOS request sent successfully')),
          );
          _loadData(); // Reload data
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${createResult['error']}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF007BFF);
    final primaryDark = const Color(0xFF0056B3);

    final aidTypes = [
      {'name': 'Food', 'icon': Icons.inventory_2, 'color': Colors.orange.shade700, 'bg': Colors.orange.shade50},
      {'name': 'Water', 'icon': Icons.water_drop, 'color': Colors.blue.shade700, 'bg': Colors.blue.shade50},
      {'name': 'Shelter', 'icon': Icons.home, 'color': Colors.green.shade700, 'bg': Colors.green.shade50},
      {'name': 'Medicine', 'icon': Icons.favorite, 'color': Colors.red.shade700, 'bg': Colors.red.shade50},
    ];

    // Convert disasters to alerts format for display
    final alerts = _disasters.take(5).map((d) {
      final severity = d['severity'] ?? 'medium';
      return {
        'type': d['name'] ?? 'Disaster Alert',
        'level': severity == 'high' || severity == 'critical' ? 'high' : 'safe',
        'location': d['location'] ?? 'Unknown',
        'time': d['start_date'] ?? 'Recent',
        'id': d['id'],
      };
    }).toList();

    final emergencyContacts = [
      {'name': 'Police', 'number': '911', 'icon': Icons.security},
      {'name': 'Fire', 'number': '101', 'icon': Icons.local_fire_department},
      {'name': 'Ambulance', 'number': '102', 'icon': Icons.local_hospital},
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Page content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 96), // leave space for bottom nav
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [primary, primaryDark]),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Emergency Dashboard', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                                SizedBox(height: 6),
                                Text('Stay safe, help is near', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.white24,
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(Icons.public, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // SOS Button
                      _ScaleOnTap(
                        onTap: _handleSOS,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4B4B),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                                  Text('Emergency', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  SizedBox(height: 2),
                                  Text('SOS - Send Help', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Loading indicator
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadData,
                                color: Colors.red.shade700,
                              ),
                            ],
                          ),
                        ),

                      // My Help Requests
                      if (!_isLoading && _helpRequests.isNotEmpty) ...[
                        Row(children: [
                          Icon(Icons.help_outline, color: primary, size: 20),
                          const SizedBox(width: 8),
                          const Text('My Help Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 10),
                        ..._helpRequests.take(3).map((request) {
                          final status = request['status'] ?? 'pending';
                          final statusColors = {
                            'pending': Colors.orange,
                            'in_progress': Colors.blue,
                            'resolved': Colors.green,
                            'cancelled': Colors.grey,
                          };
                          final statusColor = statusColors[status] ?? Colors.grey;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: statusColor.shade50,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
                              border: Border(left: BorderSide(color: statusColor.shade700, width: 4)),
                            ),
                            child: ListTile(
                              title: Text(
                                request['description'] ?? 'Help Request',
                                style: TextStyle(color: statusColor.shade900, fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (request['location'] != null)
                                    Row(children: [
                                      const Icon(Icons.place, size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(request['location'], style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                      ),
                                    ]),
                                  if (request['disaster_name'] != null)
                                    Text('Disaster: ${request['disaster_name']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status.toUpperCase().replaceAll('_', ' '),
                                  style: TextStyle(color: statusColor.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 18),
                      ],

                      // Live alerts
                      Row(children: [
                        Icon(Icons.notifications, color: primary, size: 20),
                        const SizedBox(width: 8),
                        const Text('Live Disaster Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 10),
                      alerts.isEmpty && !_isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No active disasters', style: TextStyle(color: Colors.grey)),
                            )
                          : Column(
                              children: alerts.map((alert) {
                          final isHigh = alert['level'] == 'high';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isHigh ? Colors.red.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
                              border: Border(left: BorderSide(color: isHigh ? Colors.red.shade700 : Colors.green.shade700, width: 4)),
                            ),
                            child: ListTile(
                              title: Text(alert['type']!, style: TextStyle(color: isHigh ? Colors.red.shade900 : Colors.green.shade900, fontWeight: FontWeight.w600)),
                              subtitle: Row(children: [
                                const Icon(Icons.place, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(alert['location']!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                              ]),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isHigh ? Colors.red.shade100 : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(alert['time']!, style: TextStyle(color: isHigh ? Colors.red.shade700 : Colors.green.shade700, fontSize: 12)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // Request Aid
                      const Text('Request Aid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        children: aidTypes.map((aid) {
                          return _ScaleOnTap(
                            onTap: widget.onNavigateToRequestDetails,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: aid['bg'] as Color?,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(color: aid['color'] as Color?, borderRadius: BorderRadius.circular(10)),
                                    alignment: Alignment.center,
                                    child: Icon(aid['icon'] as IconData, color: Colors.white),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(aid['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onNavigateToMap,
                              icon: const Icon(Icons.map),
                              label: const Text('Nearby Shelters'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.shield),
                              label: const Text('Safety Tips'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: primary),
                                foregroundColor: primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Emergency Contacts
                      const Text('Emergency Contacts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        physics: const NeverScrollableScrollPhysics(),
                        children: emergencyContacts.map((c) {
                          return InkWell(
                            onTap: () {
                              // Could launch dialer with url_launcher
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFFF4B4B),
                                    child: Icon(c['icon'] as IconData, color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(c['name'] as String, style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(c['number'] as String, style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom navigation (fixed)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -6))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavButton(icon: Icons.home, label: 'Home', active: true, color: primary, onTap: () {}),
                  _NavButton(icon: Icons.map, label: 'Map', active: false, onTap: widget.onNavigateToMap),
                  _NavButton(icon: Icons.notifications, label: 'Alerts', active: false, onTap: () {}),
                  _NavButton(icon: Icons.person, label: 'Profile', active: false, onTap: widget.onNavigateToProfile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple nav button used in bottom bar
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

/// Small widget that scales when tapped to mimic whileTap in motion
class _ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _ScaleOnTap({required this.child, this.onTap});

  @override
  _ScaleOnTapState createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
  _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.0, upperBound: 0.08);
    _anim = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) {
    _ctrl.reverse();
    widget.onTap?.call();
  }

  void _onCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onCancel,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) => Transform.scale(scale: _anim.value, child: child),
        child: widget.child,
      ),
    );
  }
}
