import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/widgets/receipt_modal.dart';
import '../../models/models.dart';
import '../providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(invoicesHistoryProvider);
    final salesSummaryAsync = ref.watch(salesSummaryProvider);
    final settingsAsync = ref.watch(shopSettingsProvider);
    final currency = settingsAsync.value?.currency ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & Invoices',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(invoicesHistoryProvider.notifier).refresh();
              ref.invalidate(salesSummaryProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // KPI Summary Cards
          salesSummaryAsync.when(
            data: (summary) => _buildSalesKpiHeader(summary, currency),
            loading: () => const LinearProgressIndicator(),
            error: (err, stack) => const SizedBox.shrink(),
          ),

          // Search & Date Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search Invoice # or Phone',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref
                                    .read(invoicesHistoryProvider.notifier)
                                    .filter(query: '');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      ref
                          .read(invoicesHistoryProvider.notifier)
                          .filter(query: val);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Filter by Date',
                  icon: Icon(
                    _selectedDate != null
                        ? Icons.event_available_rounded
                        : Icons.date_range_rounded,
                    color: _selectedDate != null ? const Color(0xFFE65100) : null,
                  ),
                  onPressed: () async {
                    if (_selectedDate != null) {
                      // Clear date filter
                      setState(() => _selectedDate = null);
                      ref
                          .read(invoicesHistoryProvider.notifier)
                          .filter(date: '');
                    } else {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        final dateStr =
                            DateFormat('yyyy-MM-dd').format(picked);
                        ref
                            .read(invoicesHistoryProvider.notifier)
                            .filter(date: dateStr);
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          // Invoices List
          Expanded(
            child: historyAsync.when(
              data: (invoices) {
                if (invoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No invoices found',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                  itemCount: invoices.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = invoices[index];
                    final inv = item.invoice;

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (settingsAsync.value != null) {
                          ReceiptModal.show(
                            context,
                            shopSettings: settingsAsync.value!,
                            invoice: inv,
                            items: item.items,
                          );
                        }
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    inv.invoiceNumber,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      inv.paymentMode,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    inv.customerName.isNotEmpty
                                        ? inv.customerName
                                        : 'Valued Customer',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    CurrencyUtils.format(
                                        inv.grandTotal, currency),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.items.length} items',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    inv.createdAt,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
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
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesKpiHeader(SalesSummary summary, String currency) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Sales",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyUtils.format(summary.todaySales, currency),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE65100),
                  ),
                ),
                Text(
                  '${summary.todayBills} bills today',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 44, color: Colors.orange.shade200),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Revenue',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyUtils.format(summary.totalSales, currency),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${summary.totalBills} total bills',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
