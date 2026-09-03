import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shopNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _upiIdCtrl;
  late TextEditingController _taxPercentCtrl;
  late TextEditingController _footerNoteCtrl;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _shopNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _upiIdCtrl = TextEditingController();
    _taxPercentCtrl = TextEditingController();
    _footerNoteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _upiIdCtrl.dispose();
    _taxPercentCtrl.dispose();
    _footerNoteCtrl.dispose();
    super.dispose();
  }

  void _populate(ShopSettings s) {
    if (!_initialized) {
      _shopNameCtrl.text = s.shopName;
      _phoneCtrl.text = s.phone;
      _addressCtrl.text = s.address;
      _upiIdCtrl.text = s.upiId;
      _taxPercentCtrl.text = s.taxPercent.toString();
      _footerNoteCtrl.text = s.footerNote;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(shopSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: settingsAsync.when(
        data: (settings) {
          _populate(settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Shop Identity Section
                  const Text('SHOP DETAILS',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE65100),
                          letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _shopNameCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Shop Name',
                              prefixIcon: Icon(Icons.storefront_outlined),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Contact Phone',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                final digits = v.replaceAll(RegExp(r'\D'), '');
                                if (digits.length < 10 || digits.length > 15) {
                                  return 'Enter a valid 10-digit phone number';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _addressCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Shop Address',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payments & Tax Section
                  const Text('PAYMENT & BILLING',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE65100),
                          letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _upiIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'UPI ID (for QR / Payment)',
                              hintText: 'e.g. vendor@okhdfcbank',
                              prefixIcon: Icon(Icons.qr_code_2_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _taxPercentCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Default Tax (%)',
                              hintText: '0 for no tax, or 5, 12, 18',
                              prefixIcon: Icon(Icons.percent_outlined),
                            ),
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                final val = double.tryParse(v.trim());
                                if (val == null) return 'Must be a valid number';
                                if (val < 0 || val > 100) {
                                  return 'Tax must be between 0% and 100%';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _footerNoteCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Receipt Footer Note',
                              hintText: 'e.g. Fresh & Delicious! Visit Again!',
                              prefixIcon: Icon(Icons.favorite_outline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Settings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        final updated = settings.copyWith(
                          shopName: _shopNameCtrl.text.trim().toUpperCase(),
                          phone: _phoneCtrl.text.trim(),
                          address: _addressCtrl.text.trim(),
                          upiId: _upiIdCtrl.text.trim(),
                          taxPercent:
                              double.tryParse(_taxPercentCtrl.text.trim()) ?? 0.0,
                          footerNote: _footerNoteCtrl.text.trim(),
                        );

                        await ref
                            .read(shopSettingsProvider.notifier)
                            .updateSettings(updated);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Shop settings updated successfully!'),
                              backgroundColor: Color(0xFF2E7D32),
                            ),
                          );
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // App Info
                  Center(
                    child: Text(
                      'Frankie Vendor POS v1.0.0 (Flutter)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
