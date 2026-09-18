import 'package:flutter/material.dart';
import '../../../models/medicine_order.dart';
import '../../../services/medical_shop_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final MedicineOrder order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late MedicineOrder _order;
  bool _isLoading = false;
  final MedicalShopService _shopService = MedicalShopService();

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _refreshOrder();
  }

  Future<void> _refreshOrder() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _shopService.getOrderById(_order.id);
      if (updated != null && mounted) {
        setState(() {
          _order = updated;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_order.id ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshOrder,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrder,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Card
            _buildStatusHeader(theme),
            const SizedBox(height: 20),

            // Tracking Stepper
            _buildTrackingTimeline(theme),
            const SizedBox(height: 20),

            // Order Items
            Text(
              'Items (${_order.items.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ..._order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.medication, color: theme.colorScheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.medicineName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    '${item.category ?? 'Medicine'} • ${item.dosage ?? ''} • ₹${item.unitPrice.toStringAsFixed(2)} x ${item.quantity}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '₹${_order.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Pharmacy Details
            if (_order.shopName != null) ...[
              Text(
                'Pharmacy Information',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.store)),
                  title: Text(_order.shopName!),
                  subtitle: Text(_order.shopAddress ?? 'Medical Store'),
                  trailing: _order.shopPhone != null
                      ? IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Pharmacy Phone: ${_order.shopPhone}')),
                            );
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Delivery & Order Metadata
            Text(
              'Order & Delivery Info',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Order ID', '#${_order.id ?? ''}'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Placed At', _order.formattedOrderDate),
                    const SizedBox(height: 8),
                    _buildInfoRow('Patient', _order.patientName ?? '${_order.patientId}'),
                    if (_order.caretakerId != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Ordered By Caretaker', _order.caretakerName ?? '${_order.caretakerId}'),
                    ],
                    const Divider(height: 20),
                    const Text('Delivery Address:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(_order.deliveryAddress ?? 'No address provided', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    if (_order.notes != null && _order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(_order.notes!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(ThemeData theme) {
    Color color = Colors.orange;
    IconData icon = Icons.hourglass_top;

    switch (_order.orderStatus) {
      case MedicineOrderStatus.pending:
        color = Colors.orange;
        icon = Icons.hourglass_top;
        break;
      case MedicineOrderStatus.accepted:
        color = Colors.blue;
        icon = Icons.thumb_up_alt_outlined;
        break;
      case MedicineOrderStatus.packed:
        color = Colors.indigo;
        icon = Icons.inventory_2_outlined;
        break;
      case MedicineOrderStatus.ready:
        color = Colors.teal;
        icon = Icons.local_shipping_outlined;
        break;
      case MedicineOrderStatus.delivered:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case MedicineOrderStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
    }

    return Card(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _order.statusDisplayName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Updated: ${_order.formattedOrderDate}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingTimeline(ThemeData theme) {
    if (_order.orderStatus == MedicineOrderStatus.rejected) {
      return Card(
        color: Colors.red.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.shade200),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This order was rejected by the pharmacy. Any pending charges will be refunded.',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final steps = [
      {'status': MedicineOrderStatus.pending, 'label': 'Placed'},
      {'status': MedicineOrderStatus.accepted, 'label': 'Accepted'},
      {'status': MedicineOrderStatus.packed, 'label': 'Packed'},
      {'status': MedicineOrderStatus.ready, 'label': 'Ready'},
      {'status': MedicineOrderStatus.delivered, 'label': 'Delivered'},
    ];

    final currentIdx = steps.indexWhere((s) => s['status'] == _order.orderStatus);
    final activeStep = currentIdx >= 0 ? currentIdx : 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (idx) {
            final isCompleted = idx <= activeStep;
            final isCurrent = idx == activeStep;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text('${idx + 1}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[idx]['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? theme.colorScheme.primary : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
