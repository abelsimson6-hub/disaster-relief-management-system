// lib/src/screens/request_details.dart
import 'package:flutter/material.dart';

class RequestDetails extends StatelessWidget {
  final VoidCallback onBack;
  const RequestDetails({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF2563EB);
    final primaryDark = const Color(0xFF1D4ED8);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primary, primaryDark]),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button + title row
                  Row(
                    children: [
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text('Request Details',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Medical Supplies - Urgent', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Status row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatusChip(
                          color: Colors.red.shade100,
                          textColor: Colors.red.shade700,
                          icon: Icons.warning_amber_rounded,
                          label: 'Urgent Priority',
                        ),
                        _StatusChip.outline(
                          label: '15 mins ago',
                          icon: Icons.access_time,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Map preview card
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                      clipBehavior: Clip.hardEdge,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Map / photo background
                                Image.network(
                                  'https://images.unsplash.com/photo-1607264469190-4abbbd14f5ab?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
                                  fit: BoxFit.cover,
                                  color: Colors.black.withOpacity(0.35),
                                  colorBlendMode: BlendMode.darken,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1) : null));
                                  },
                                  errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                                ),

                                // Center pin
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.red.shade600, shape: BoxShape.circle, boxShadow: const [
                                      BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))
                                    ]),
                                    child: const Icon(Icons.location_on, color: Colors.white, size: 28),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Map address area
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.place, color: Color(0xFF2563EB)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('Downtown Medical Center', style: TextStyle(fontWeight: FontWeight.w600)),
                                      SizedBox(height: 4),
                                      Text('123 Main Street, City Center', style: TextStyle(color: Colors.black54)),
                                      SizedBox(height: 6),
                                      Text('1.2 km away', style: TextStyle(color: Color(0xFF2563EB))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Requester Information
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Requester Information', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    gradient: LinearGradient(colors: [primary, primaryDark]),
                                  ),
                                  child: const Center(child: Icon(Icons.person, color: Colors.white, size: 28)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    const Text('Sarah Johnson', style: TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.verified, size: 16, color: Colors.black54),
                                          SizedBox(width: 6),
                                          Text('Verified User', style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ]),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Contact cards
                            Column(
                              children: [
                                _ContactRow(icon: Icons.phone, label: 'Phone', value: '+1 (555) 123-4567', accent: primary, onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Call tapped (mock)')));
                                }),
                                const SizedBox(height: 8),
                                _ContactRow(icon: Icons.email, label: 'Email', value: 'sarah.j@email.com', accent: primary, onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email tapped (mock)')));
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Request Description
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Request Description', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          const Text(
                            'Urgent need for insulin and diabetes medication. Patient is currently at Downtown Medical Center and requires immediate assistance. Please bring any available supplies.',
                            style: TextStyle(color: Colors.black54, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.yellow.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.yellow.shade200)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.yellow.shade800),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                                    Text('Special Note', style: TextStyle(fontWeight: FontWeight.w600)),
                                    SizedBox(height: 4),
                                    Text('Medical emergency - time sensitive', style: TextStyle(color: Colors.black87)),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as completed (mock)')));
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Mark as Completed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Call tapped (mock)')));
                                },
                                icon: const Icon(Icons.phone),
                                label: const Text('Call'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: primary),
                                  foregroundColor: primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate tapped (mock)')));
                                },
                                icon: const Icon(Icons.place),
                                label: const Text('Navigate'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: primary),
                                  foregroundColor: primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// small status chip used in the top row
class _StatusChip extends StatelessWidget {
  final Color color;
  final Color textColor;
  final IconData icon;
  final String label;
  final bool outline;

  const _StatusChip({
    required this.color,
    required this.textColor,
    required this.icon,
    required this.label,
  })  : outline = false;

  const _StatusChip.outline({required this.label, required this.icon})
      : color = Colors.transparent,
        textColor = Colors.black54,
        outline = true;

  @override
  Widget build(BuildContext context) {
    if (outline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
        child: Row(children: [Icon(icon, size: 16, color: Colors.black54), const SizedBox(width: 8), Text(label, style: TextStyle(color: textColor))]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [Icon(icon, size: 16, color: textColor), const SizedBox(width: 8), Text(label, style: TextStyle(color: textColor))]),
    );
  }
}

/// Contact row widget
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback onTap;

  const _ContactRow({required this.icon, required this.label, required this.value, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
