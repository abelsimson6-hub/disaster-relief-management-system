import 'package:flutter/material.dart';
import 'package:relief/services/api_service.dart';

class DonorDashboard extends StatefulWidget {
  final VoidCallback onNavigateToMap;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToDonationDetails;

  const DonorDashboard({
    super.key,
    required this.onNavigateToMap,
    required this.onNavigateToProfile,
    required this.onNavigateToDonationDetails,
  });

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> myDonations = [];
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
      final donationsResult = await ApiService.getDonations();

      if (mounted) {
        setState(() {
          if (requestsResult['success'] == true) {
            final helpRequests = requestsResult['data'] ?? [];
            requests = helpRequests.map<Map<String, dynamic>>((r) {
              return {
                'id': r['id'],
                'victim': r['victim_name'] ?? 'Unknown',
                'need': r['description'] ?? '',
                'location': r['location'] ?? 'Unknown',
                'verified': r['status'] != 'pending',
                'urgency': r['status'] == 'pending' ? 'high' : 'normal',
              };
            }).toList();
          }
          if (donationsResult['success'] == true) {
            final donations = donationsResult['data'] ?? [];
            myDonations = donations.map<Map<String, dynamic>>((d) {
              return {
                'item': d['donor_name'] ?? 'Donation',
                'status': 'delivered',
                'date': _formatDate(d['donation_date']),
              };
            }).toList();
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays} days ago';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF007BFF);
    final primaryDark = const Color(0xFF0056B3);
    final purple600 = Colors.purple.shade600;

    final donationTypes = [
      {
        'name': 'Money',
        'icon': Icons.currency_rupee,
        'color': Colors.green.shade700,
        'bg': Colors.green.shade50,
      },
      {
        'name': 'Food',
        'icon': Icons.inventory_2,
        'color': Colors.orange.shade700,
        'bg': Colors.orange.shade50,
      },
      {
        'name': 'Clothes',
        'icon': Icons.checkroom,
        'color': Colors.purple.shade700,
        'bg': Colors.purple.shade50,
      },
      {
        'name': 'Medicine',
        'icon': Icons.medical_services,
        'color': Colors.red.shade700,
        'bg': Colors.red.shade50,
      },
    ];

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
              padding: const EdgeInsets.only(bottom: 96),
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
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Donor Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your generosity changes lives',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 14),

                      // Impact summary card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          // blur/backdrop not necessary; keep simple
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Impact',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _ImpactTile(
                                  title: '₹2,450',
                                  subtitle: 'Total Donated',
                                ),
                                _ImpactTile(
                                  title: '18',
                                  subtitle: 'Families Helped',
                                ),
                                _ImpactTile(
                                  title: '12',
                                  subtitle: 'Active Donations',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Donate
                      const Text(
                        'Donate Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        children: donationTypes.map((type) {
                          return _ScaleOnTap(
                            onTap: widget.onNavigateToDonationDetails,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: type['bg'] as Color?,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: type['color'] as Color?,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      type['icon'] as IconData,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    type['name'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // Verified Requests
                      const Text(
                        'Verified Victim Requests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: requests.map((request) {
                          final urgency = request['urgency'] as String;
                          final badgeColor = urgency == 'urgent'
                              ? Colors.red.shade100
                              : urgency == 'high'
                              ? Colors.orange.shade100
                              : Colors.blue.shade100;
                          final badgeTextColor = urgency == 'urgent'
                              ? Colors.red.shade700
                              : urgency == 'high'
                              ? Colors.orange.shade700
                              : Colors.blue.shade700;
                          return _ScaleOnTap(
                            onTap: widget.onNavigateToDonationDetails,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  request['victim'] as String,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (request['verified'] as bool)
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.blue,
                                                    size: 16,
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              request['need'] as String,
                                              style: const TextStyle(
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.place,
                                                  size: 14,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  request['location'] as String,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeColor,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          urgency,
                                          style: TextStyle(
                                            color: badgeTextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: widget.onNavigateToDonationDetails,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text('Donate Now'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // Track Donations
                      const Text(
                        'Track Your Donations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: myDonations.map((donation) {
                          final status = donation['status'] as String;
                          final progressValue = status == 'delivered'
                              ? 1.0
                              : 0.6;
                          final badgeColor = status == 'delivered'
                              ? Colors.green.shade100
                              : Colors.blue.shade100;
                          final badgeTextColor = status == 'delivered'
                              ? Colors.green.shade700
                              : Colors.blue.shade700;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            donation['item'] as String,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                donation['date'] as String,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badgeColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: badgeTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progressValue,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    color: primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // Sponsor Relief Camp card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade50,
                              Colors.blue.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  color: purple600,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Sponsor a Relief Camp',
                                  style: TextStyle(
                                    color: purple600,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Support an entire community with sustained aid and resources',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: purple600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Learn More'),
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

          // Bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavButton(
                    icon: Icons.home,
                    label: 'Home',
                    active: true,
                    color: primary,
                    onTap: () {},
                  ),
                  _NavButton(
                    icon: Icons.map,
                    label: 'Map',
                    active: false,
                    onTap: widget.onNavigateToMap,
                  ),
                  _NavButton(
                    icon: Icons.notifications,
                    label: 'Alerts',
                    active: false,
                    onTap: () {},
                  ),
                  _NavButton(
                    icon: Icons.person,
                    label: 'Profile',
                    active: false,
                    onTap: widget.onNavigateToProfile,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactTile extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ImpactTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
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

  const _NavButton({
    required this.icon,
    required this.label,
    required this.active,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? activeColor : Colors.grey.shade400),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: active ? activeColor : Colors.grey.shade400,
            ),
          ),
        ],
      ),
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

class _ScaleOnTapState extends State<_ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.08,
    );
    _anim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
        builder: (context, child) =>
            Transform.scale(scale: _anim.value, child: child),
        child: widget.child,
      ),
    );
  }
}
