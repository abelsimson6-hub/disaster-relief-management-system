// lib/src/screens/donation_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../services/api_service.dart';

class DonationDetailsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSubmitted; // optional callback when donation is submitted

  const DonationDetailsScreen({super.key, this.onBack, this.onSubmitted});

  @override
  State<DonationDetailsScreen> createState() => _DonationDetailsScreenState();
}

class _DonationDetailsScreenState extends State<DonationDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _donationType = 'Food';
  final _locationCtrl = TextEditingController();
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  bool _pickupNow = true;

  // dynamic items list: each item has name, qty, notes
  final List<_ItemRowModel> _items = [ _ItemRowModel() ];

  // money donation special
  final _moneyAmountCtrl = TextEditingController();

  @override
  void dispose() {
    _locationCtrl.dispose();
    _moneyAmountCtrl.dispose();
    for (var it in _items) {
      it.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_ItemRowModel());
    });
  }

  void _removeItem(int index) {
    setState(() {
      if (_items.length > 1) {
        _items.removeAt(index);
      } else {
        // clear if only one left
        _items[0].clear();
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _pickupDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (d != null) setState(() => _pickupDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _pickupTime ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _pickupTime = t);
  }

  /// Impact calculation (simple heuristics):
  /// - totalItems = sum(qty)
  /// - familiesHelped = ceil(totalItems / 5)
  /// - estimatedValue: if money => entered amount; else assume each item value = 100 (mock)
  Map<String, dynamic> _computeImpact() {
    int totalQty = 0;
    for (var it in _items) {
      final q = int.tryParse(it.qtyCtrl.text) ?? 0;
      totalQty += q;
    }

    double estimatedValue = 0;
    if (_donationType == 'Money') {
      estimatedValue = double.tryParse(_moneyAmountCtrl.text) ?? 0;
    } else {
      estimatedValue = totalQty * 100.0; // mock unit value
    }

    final familiesHelped = (totalQty > 0) ? ((totalQty / 5).ceil()) : 0;

    return {
      'totalItems': totalQty,
      'familiesHelped': familiesHelped,
      'estimatedValue': estimatedValue,
    };
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors before submitting')),
      );
      return;
    }

    // Get user info from AppState
    final appState = Provider.of<AppState>(context, listen: false);
    final donorName = appState.username ?? 'Anonymous';
    final donorType = 'individual'; // Could be made configurable
    final contactEmail = appState.email;

    // Build items_data array
    List<Map<String, dynamic>> itemsData = [];
    
    if (_donationType == 'Money') {
      // For money donations, create a special item
      final amount = double.tryParse(_moneyAmountCtrl.text) ?? 0;
      if (amount > 0) {
        itemsData.add({
          'name': 'Money Donation',
          'category': 'other',
          'quantity': amount.toString(),
        });
      }
    } else {
      // For other donation types, process items
      for (var item in _items) {
        final name = item.nameCtrl.text.trim();
        final qty = item.qtyCtrl.text.trim();
        
        if (name.isNotEmpty && qty.isNotEmpty) {
          // Map donation type to resource category
          String category = 'other';
          switch (_donationType.toLowerCase()) {
            case 'food':
              category = 'food';
              break;
            case 'medicine':
              category = 'medical';
              break;
            case 'clothes':
              category = 'clothing';
              break;
            default:
              category = 'other';
          }
          
          itemsData.add({
            'name': name,
            'category': category,
            'quantity': qty,
          });
        }
      }
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Call API to create donation
      final result = await ApiService.createDonation(
        donorName: donorName,
        donorType: donorType,
        contactEmail: contactEmail,
        itemsData: itemsData.isNotEmpty ? itemsData : null,
      );

      // Close loading indicator
      if (mounted) Navigator.of(context).pop();

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Donation submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSubmitted?.call();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit donation: ${result['error'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading indicator
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting donation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final impact = _computeImpact();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack ?? () => Navigator.of(context).pop()),
        backgroundColor: const Color(0xFF007BFF),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      // Donation type & toggle money-handling
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _donationType,
                              decoration: InputDecoration(labelText: 'Donation Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                              items: const [
                                DropdownMenuItem(value: 'Money', child: Text('Money')),
                                DropdownMenuItem(value: 'Food', child: Text('Food')),
                                DropdownMenuItem(value: 'Clothes', child: Text('Clothes')),
                                DropdownMenuItem(value: 'Medicine', child: Text('Medicine')),
                                DropdownMenuItem(value: 'Other', child: Text('Other')),
                              ],
                              onChanged: (v) => setState(() => _donationType = v ?? 'Food'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // If Money, show amount
                      if (_donationType == 'Money')
                        Column(children: [
                          TextFormField(
                            controller: _moneyAmountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter amount';
                              final n = double.tryParse(v);
                              if (n == null || n <= 0) return 'Enter a valid amount';
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                        ]),

                      // Items dynamic list (only for non-money types; but we allow for all)
                      const Text('Items', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final it = _items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: it.nameCtrl,
                                          decoration: const InputDecoration(labelText: 'Item name', border: OutlineInputBorder(), isDense: true),
                                          validator: (v) {
                                            if ((v ?? '').trim().isEmpty) return 'Enter item name';
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 90,
                                        child: TextFormField(
                                          controller: it.qtyCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder(), isDense: true),
                                          validator: (v) {
                                            final n = int.tryParse(v ?? '');
                                            if (n == null || n <= 0) return 'Invalid';
                                            return null;
                                          },
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: it.notesCtrl,
                                    decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder(), isDense: true),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _removeItem(index),
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        label: const Text('Remove', style: TextStyle(color: Colors.red)),
                                      ),
                                      const Spacer(),
                                      if (index == _items.length - 1)
                                        ElevatedButton.icon(
                                          onPressed: _addItem,
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add item'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 6),

                      // Pickup location
                      TextFormField(
                        controller: _locationCtrl,
                        decoration: InputDecoration(
                          labelText: 'Pickup location',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          hintText: 'Enter pickup address (or tap to pick on map)',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.my_location),
                            onPressed: () {
                              // TODO: integrate map/location picker (or Provider)
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Map picker not implemented (mock)')));
                            },
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter pickup location';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Pickup now or schedule
                      Row(
                        children: [
                          Checkbox(
                            value: _pickupNow,
                            onChanged: (v) => setState(() => _pickupNow = v ?? true),
                          ),
                          const Text('Pickup ASAP'),
                          const Spacer(),
                          if (!_pickupNow)
                            Row(children: [
                              TextButton.icon(onPressed: _pickDate, icon: const Icon(Icons.date_range), label: Text(_pickupDate == null ? 'Pick date' : _pickupDate!.toLocal().toIso8601String().split('T').first)),
                              const SizedBox(width: 6),
                              TextButton.icon(onPressed: _pickTime, icon: const Icon(Icons.access_time), label: Text(_pickupTime == null ? 'Pick time' : _pickupTime!.format(context))),
                            ])
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Impact preview
                      _buildImpactPreview(impact),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // Actions: Submit / Cancel
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: const Color(0xFF007BFF)),
                        child: const Text('Submit Donation'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImpactPreview(Map<String, dynamic> impact) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Impact Preview', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              _impactTile('Total items', '${impact['totalItems']}'),
              const SizedBox(width: 8),
              _impactTile('Families helped', '${impact['familiesHelped']}'),
              const SizedBox(width: 8),
              _impactTile('Est. value', '₹${impact['estimatedValue'].toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Notes: This is an estimate. Replace heuristics with real backend calculations when integrating.'),
        ]),
      ),
    );
  }

  Widget _impactTile(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Model for item row controllers
class _ItemRowModel {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  void clear() {
    nameCtrl.clear();
    qtyCtrl.clear();
    notesCtrl.clear();
  }

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    notesCtrl.dispose();
  }
}
