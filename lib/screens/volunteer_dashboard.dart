// lib/src/screens/volunteer_dashboard.dart
import 'package:flutter/material.dart';
import 'package:relief/services/api_service.dart';

class VolunteerDashboard extends StatefulWidget {
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToRequestDetails;
  final VoidCallback onNavigateToMap;

  const VolunteerDashboard({
    super.key,
    required this.onNavigateToProfile,
    required this.onNavigateToRequestDetails,
    required this.onNavigateToMap,
  });

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  String filter = 'all'; // 'all' | 'urgent' | 'nearby' | 'assigned'
  bool isActive = true;
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _tasks = [];
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
      final requestsResult = await ApiService.getHelpRequests();
      final tasksResult = await ApiService.getTasks();

      if (mounted) {
        setState(() {
          if (requestsResult['success'] == true) {
            final requests = requestsResult['data'] ?? [];
            _requests = requests.map<Map<String, dynamic>>((r) {
              return {
                'id': r['id'],
                'name': r['victim_name'] ?? 'Unknown',
                'need': r['description'] ?? '',
                'location': r['location'] ?? 'Unknown',
                'distance': 'N/A',
                'urgency': r['status'] == 'pending' ? 'urgent' : 'normal',
                'time': _formatTime(r['requested_at']),
                'status': r['status'] == 'pending' ? 'available' : r['status'],
                'raw': r,
              };
            }).toList();
          }
          if (tasksResult['success'] == true) {
            final tasks = tasksResult['data'] ?? [];
            _tasks = tasks.map<Map<String, dynamic>>((t) {
              return {
                'id': t['id'],
                'name': t['volunteer_name'] ?? 'Unknown',
                'need': t['task_description'] ?? t['help_request_description'] ?? '',
                'location': 'N/A',
                'distance': 'N/A',
                'urgency': t['status'] == 'assigned' ? 'urgent' : 'normal',
                'time': _formatTime(t['assigned_at']),
                'status': t['status'] ?? 'available',
                'raw': t,
              };
            }).toList();
            // Merge tasks into requests for display
            _requests = [..._requests, ..._tasks];
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

  String _formatTime(String? timeStr) {
    if (timeStr == null) return 'Unknown';
    try {
      final time = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(time);
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} mins ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else {
        return '${diff.inDays} days ago';
      }
    } catch (e) {
      return timeStr;
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    var list = _requests;
    if (filter == 'urgent') {
      list = list.where((r) => r['urgency'] == 'urgent').toList();
    } else if (filter == 'nearby') {
      // As an example, treat distance < 2 km as nearby
      list = list.where((r) {
        final d = double.tryParse((r['distance'] as String).split(' ').first) ?? 999.0;
        return d <= 2.0;
      }).toList();
    } else if (filter == 'assigned') {
      list = list.where((r) => r['status'] == 'assigned').toList();
    }
    // search filter
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) {
        return (r['name'] as String).toLowerCase().contains(q) ||
            (r['need'] as String).toLowerCase().contains(q) ||
            (r['location'] as String).toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _setFilter(String f) => setState(() => filter = f);
  void _toggleActive(bool val) => setState(() => isActive = val);

  @override
  Widget build(BuildContext context) {
    final green1 = Colors.green.shade600;
    final green2 = Colors.green.shade700;

    return Scaffold(
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(
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
            )
          else
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 92),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [green1, green2]),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 36, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Volunteer Dashboard', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text('Making a difference together', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      // Status card
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.shade400 : Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(isActive ? 'Active' : 'Offline', style: const TextStyle(color: Colors.white)),
                            ]),
                            Switch(
                              value: isActive,
                              onChanged: _toggleActive,
                              activeThumbColor: Colors.white,
                              activeTrackColor: Colors.green.shade300,
                              inactiveThumbColor: Colors.grey.shade200,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: Column(
                    children: [
                      // Search bar
                      Stack(
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Search requests...',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            bottom: 6,
                            child: IconButton(
                              onPressed: () {
                                // filter button tapped — could open additional filters
                                showModalBottomSheet(context: context, builder: (_) => _buildFilterSheet());
                              },
                              icon: const Icon(Icons.filter_list, color: Colors.grey),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Filters as chips
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: const ['all', 'urgent', 'nearby', 'assigned'].length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final key = ['all', 'urgent', 'nearby', 'assigned'][index];
                            final label = key[0].toUpperCase() + key.substring(1);
                            final selected = filter == key;
                            return ChoiceChip(
                              label: Text(label),
                              selected: selected,
                              onSelected: (_) => _setFilter(key),
                              selectedColor: Colors.blue.shade600,
                              backgroundColor: Colors.grey.shade200,
                              labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quick actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onNavigateToMap,
                              icon: const Icon(Icons.location_on),
                              label: const Text('Mark Safe Zone'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green1,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Submit report flow (placeholder)
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submit Report tapped (mock)')));
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Submit Report'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: green1),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                foregroundColor: green1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Requests list
                      Column(
                        children: _filteredRequests.map((r) {
                          final isUrgent = r['urgency'] == 'urgent';
                          final isAvailable = r['status'] == 'available';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ScaleOnTap(
                              onTap: () {
                                // show details
                                widget.onNavigateToRequestDetails();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(colors: [Color(0xFF007BFF), Color(0xFF0056B3)]),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.person, color: Colors.white),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Row(
                                              children: [
                                                Text(r['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                                const SizedBox(width: 8),
                                                if (isUrgent)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                                                    child: Row(children: [
                                                      const Icon(Icons.warning, size: 14, color: Colors.red),
                                                      const SizedBox(width: 6),
                                                      Text('Urgent', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                                                    ]),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(r['need'], style: const TextStyle(color: Colors.black54)),
                                          ]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Row(children: [
                                          const Icon(Icons.place, size: 14, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(r['location'], style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                        ]),
                                        const SizedBox(width: 14),
                                        Row(children: [
                                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(r['time'], style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                        ]),
                                        const Spacer(),
                                        Row(children: [
                                          const Icon(Icons.location_pin, size: 14, color: Color(0xFF007BFF)),
                                          const SizedBox(width: 6),
                                          Text(r['distance'], style: const TextStyle(fontSize: 13, color: Color(0xFF007BFF))),
                                        ]),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        if (isAvailable) ...[
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: widget.onNavigateToRequestDetails,
                                              icon: const Icon(Icons.inventory_2),
                                              label: const Text('Assist Now'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF007BFF),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton(
                                            onPressed: widget.onNavigateToRequestDetails,
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            child: const Text('View'),
                                          ),
                                        ] else ...[
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                // mark completed mock
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked completed (mock)')));
                                              },
                                              icon: const Icon(Icons.check_circle),
                                              label: const Text('Mark Completed'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green.shade600,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          )
                                        ]
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Navigation
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
                  _NavButton(icon: Icons.home, label: 'Home', active: true, color: green1, onTap: () {}),
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

  Widget _buildFilterSheet() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Advanced Filters', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ListTile(
          title: const Text('All'),
          leading: Radio<String>(value: 'all', groupValue: filter, onChanged: (v) => setState(() => filter = v!)),
        ),
        ListTile(
          title: const Text('Urgent only'),
          leading: Radio<String>(value: 'urgent', groupValue: filter, onChanged: (v) => setState(() => filter = v!)),
        ),
        ListTile(
          title: const Text('Nearby (<= 2 km)'),
          leading: Radio<String>(value: 'nearby', groupValue: filter, onChanged: (v) => setState(() => filter = v!)),
        ),
        ListTile(
          title: const Text('Assigned'),
          leading: Radio<String>(value: 'assigned', groupValue: filter, onChanged: (v) => setState(() => filter = v!)),
        ),
        const SizedBox(height: 8),
      ]),
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

/// Scales child slightly while pressed to mimic motion's whileTap
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

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) {
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
