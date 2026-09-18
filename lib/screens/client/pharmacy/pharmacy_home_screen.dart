import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/medicine_order.dart';
import '../../../models/shop_medicine.dart';
import '../../../models/shop_profile.dart';
import '../../../services/auth_service.dart';
import '../../../services/medical_shop_service.dart';
import '../../../widgets/app_drawer.dart';

class PharmacyHomeScreen extends StatefulWidget {
  const PharmacyHomeScreen({super.key});

  @override
  State<PharmacyHomeScreen> createState() => _PharmacyHomeScreenState();
}

class _PharmacyHomeScreenState extends State<PharmacyHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MedicalShopService _shopService = MedicalShopService();

  ShopProfile? _profile;
  Map<String, dynamic>? _stats;
  List<ShopMedicine> _inventory = [];
  List<MedicineOrder> _orders = [];

  bool _isLoading = true;
  String _inventorySearch = '';
  String _selectedInventoryCategory = 'All';
  MedicineOrderStatus? _orderStatusFilter;

  final List<String> _categories = [
    'All',
    'Tablets',
    'Syrup',
    'Injection',
    'Pain Relief',
    'Antibiotics',
    'Vitamins',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final profFuture = _shopService.getPharmacyProfile();
      final statsFuture = _shopService.getPharmacyStats();
      final invFuture = _shopService.getPharmacyInventory();
      final ordersFuture = _shopService.getShopOrders();

      final results = await Future.wait([profFuture, statsFuture, invFuture, ordersFuture]);

      if (mounted) {
        setState(() {
          _profile = results[0] as ShopProfile?;
          _stats = results[1] as Map<String, dynamic>?;
          _inventory = results[2] as List<ShopMedicine>;
          _orders = results[3] as List<MedicineOrder>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Inventory Add / Edit Dialog
  void _showAddEditMedicineDialog([ShopMedicine? existing]) {
    final nameCtrl = TextEditingController(text: existing?.medicineName ?? '');
    String category = existing?.category ?? 'Tablets';
    final dosageCtrl = TextEditingController(text: existing?.dosage ?? '500mg');
    final priceCtrl = TextEditingController(text: existing != null ? existing.price.toString() : '50.0');
    final stockCtrl = TextEditingController(text: existing != null ? existing.stockQuantity.toString() : '100');
    final batchCtrl = TextEditingController(text: existing?.batchNumber ?? '');
    final mfgCtrl = TextEditingController(text: existing?.manufacturer ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    bool reqRx = existing?.requiresPrescription ?? false;
    DateTime expiryDate = existing?.expiryDate ?? DateTime.now().add(const Duration(days: 180));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Medicine to Inventory' : 'Edit Inventory Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medication),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categories.contains(category) ? category : 'Tablets',
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.where((c) => c != 'All').map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dosageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Dosage *',
                          hintText: '500mg',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Price (₹) *',
                          hintText: '99.00',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock Qty *',
                          hintText: '50',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: batchCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Batch No.',
                          hintText: 'BTH-892',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: expiryDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) {
                      setDialogState(() => expiryDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date (DD/MM/YYYY) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(expiryDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mfgCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer',
                    hintText: 'e.g. Cipla / Sun Pharma',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description / Usage',
                    hintText: 'e.g. Used for fever and mild pain',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Prescription Required', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Customers must attach doctor prescription', style: TextStyle(fontSize: 12)),
                  value: reqRx,
                  onChanged: (val) {
                    setDialogState(() => reqRx = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final dosage = dosageCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;

                if (name.isEmpty || dosage.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid name, dosage, and price.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);

                final payload = {
                  'medicineName': name,
                  'category': category,
                  'dosage': dosage,
                  'price': price,
                  'stockQuantity': stock,
                  'expiryDate': DateFormat('yyyy-MM-dd').format(expiryDate),
                  'batchNumber': batchCtrl.text.trim().isEmpty ? null : batchCtrl.text.trim(),
                  'manufacturer': mfgCtrl.text.trim().isEmpty ? null : mfgCtrl.text.trim(),
                  'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  'requiresPrescription': reqRx,
                };

                bool ok = false;
                if (existing == null) {
                  final created = await _shopService.addMedicineToInventory(payload);
                  ok = created != null;
                } else if (existing.id != null) {
                  ok = await _shopService.updateInventoryMedicine(existing.id!, payload);
                }

                if (!mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(existing == null ? 'Medicine added to inventory!' : 'Medicine updated!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadAllData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save medicine. Please check input.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(existing == null ? 'Add Medicine' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMedicine(ShopMedicine med) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Text('Are you sure you want to delete "${med.medicineName}" from your shop inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (med.id != null) {
                final ok = await _shopService.deleteInventoryMedicine(med.id!);
                if (!mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medicine removed from inventory'), backgroundColor: Colors.red),
                  );
                  _loadAllData();
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Update order status
  Future<void> _updateOrderStatus(MedicineOrder order, MedicineOrderStatus newStatus) async {
    if (order.id == null) return;
    final ok = await _shopService.updateOrderStatus(order.id!, newStatus.name);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.id} status updated to ${newStatus.name.toUpperCase()}'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAllData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update order status.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(_profile?.shopName ?? 'Pharmacy Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Orders'),
            Tab(icon: Icon(Icons.store), text: 'Shop Profile'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInventoryTab(theme),
                _buildOrdersTab(theme),
                _buildProfileTab(theme, auth),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Medicine'),
              onPressed: () => _showAddEditMedicineDialog(),
            )
          : null,
    );
  }

  // ================= TAB 1: INVENTORY =================
  Widget _buildInventoryTab(ThemeData theme) {
    final filtered = _inventory.where((item) {
      final matchesSearch = _inventorySearch.isEmpty ||
          item.medicineName.toLowerCase().contains(_inventorySearch.toLowerCase()) ||
          (item.manufacturer != null && item.manufacturer!.toLowerCase().contains(_inventorySearch.toLowerCase()));
      final matchesCategory = _selectedInventoryCategory == 'All' || item.category == _selectedInventoryCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: Column(
        children: [
          // Stat chips row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Row(
              children: [
                _buildStatMiniCard('Total', '${_stats?['totalMedicines'] ?? _inventory.length}', Colors.blue),
                const SizedBox(width: 8),
                _buildStatMiniCard('Low Stock', '${_stats?['lowStockCount'] ?? 0}', Colors.orange),
                const SizedBox(width: 8),
                _buildStatMiniCard('Expired', '${_stats?['expiredCount'] ?? 0}', Colors.red),
                const SizedBox(width: 8),
                _buildStatMiniCard('Pending Orders', '${_stats?['pendingOrdersCount'] ?? 0}', Colors.teal),
              ],
            ),
          ),

          // Search & Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search inventory medicines...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                setState(() => _inventorySearch = val);
              },
            ),
          ),

          // Category Chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSelected = _selectedInventoryCategory == cat;
                return FilterChip(
                  selected: isSelected,
                  label: Text(cat),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.onPrimary : null,
                  ),
                  selectedColor: theme.colorScheme.primary,
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() => _selectedInventoryCategory = cat);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Items List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No medicines found in inventory',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Medicine'),
                          onPressed: () => _showAddEditMedicineDialog(),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final item = filtered[idx];
                      return _buildInventoryCard(context, item, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMiniCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, ShopMedicine item, ThemeData theme) {
    final isOutOfStock = item.isOutOfStock;
    final isExpired = item.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isExpired
            ? BorderSide(color: Colors.red.shade300, width: 1.2)
            : (item.isExpiringSoon
                ? BorderSide(color: Colors.orange.shade300, width: 1)
                : BorderSide.none),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medication, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.medicineName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${item.category} • ${item.dosage}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Stock: ${item.stockQuantity}',
                    style: TextStyle(
                      color: isOutOfStock ? Colors.red : Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.red.withValues(alpha: 0.1)
                        : (item.isExpiringSoon
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Exp: ${item.formattedExpiryDate}',
                    style: TextStyle(
                      color: isExpired
                          ? Colors.red
                          : (item.isExpiringSoon ? Colors.orange.shade800 : Colors.blue.shade800),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (item.requiresPrescription)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Rx Required',
                      style: TextStyle(color: Colors.deepPurple, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),

            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.batchNumber != null ? 'Batch: ${item.batchNumber}' : 'Mfg: ${item.manufacturer ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                      onPressed: () => _showAddEditMedicineDialog(item),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _confirmDeleteMedicine(item),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 2: ORDERS =================
  Widget _buildOrdersTab(ThemeData theme) {
    final filtered = _orders.where((o) {
      if (_orderStatusFilter == null) return true;
      return o.orderStatus == _orderStatusFilter;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: Column(
        children: [
          // Order Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildOrderStatusFilterChip('All Orders', null),
                const SizedBox(width: 8),
                _buildOrderStatusFilterChip('Pending', MedicineOrderStatus.pending),
                const SizedBox(width: 8),
                _buildOrderStatusFilterChip('Accepted', MedicineOrderStatus.accepted),
                const SizedBox(width: 8),
                _buildOrderStatusFilterChip('Packed', MedicineOrderStatus.packed),
                const SizedBox(width: 8),
                _buildOrderStatusFilterChip('Ready', MedicineOrderStatus.ready),
                const SizedBox(width: 8),
                _buildOrderStatusFilterChip('Delivered', MedicineOrderStatus.delivered),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No orders in this category',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final order = filtered[idx];
                      return _buildPharmacyOrderCard(context, order, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusFilterChip(String label, MedicineOrderStatus? status) {
    final isSelected = _orderStatusFilter == status;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      showCheckmark: false,
      onSelected: (_) {
        setState(() => _orderStatusFilter = status);
      },
    );
  }

  Widget _buildPharmacyOrderCard(BuildContext context, MedicineOrder order, ThemeData theme) {
    Color statusColor;
    switch (order.orderStatus) {
      case MedicineOrderStatus.pending:
        statusColor = Colors.orange;
        break;
      case MedicineOrderStatus.accepted:
        statusColor = Colors.blue;
        break;
      case MedicineOrderStatus.packed:
        statusColor = Colors.indigo;
        break;
      case MedicineOrderStatus.ready:
        statusColor = Colors.teal;
        break;
      case MedicineOrderStatus.delivered:
        statusColor = Colors.green;
        break;
      case MedicineOrderStatus.rejected:
        statusColor = Colors.red;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.statusDisplayName,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Customer: ${order.patientName ?? order.patientId}', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (order.caretakerId != null)
              Text('Placed by Caretaker: ${order.caretakerName ?? order.caretakerId}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Address: ${order.deliveryAddress}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            const SizedBox(height: 8),

            // Items summary
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.medicineName} (${item.dosage}) x ${item.quantity}', style: const TextStyle(fontSize: 12)),
                        Text('₹${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.formattedOrderDate, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                Text(
                  'Total: ₹${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
                ),
              ],
            ),
            const Divider(height: 20),

            // Order fulfillment actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (order.orderStatus == MedicineOrderStatus.pending) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept Order'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () => _updateOrderStatus(order, MedicineOrderStatus.accepted),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: const Text('Reject', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    onPressed: () => _updateOrderStatus(order, MedicineOrderStatus.rejected),
                  ),
                ] else if (order.orderStatus == MedicineOrderStatus.accepted) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.inventory_2, size: 16),
                    label: const Text('Mark as Packed'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    onPressed: () => _updateOrderStatus(order, MedicineOrderStatus.packed),
                  ),
                ] else if (order.orderStatus == MedicineOrderStatus.packed) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.local_shipping, size: 16),
                    label: const Text('Mark Ready for Delivery/Pickup'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    onPressed: () => _updateOrderStatus(order, MedicineOrderStatus.ready),
                  ),
                ] else if (order.orderStatus == MedicineOrderStatus.ready) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Mark as Delivered'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () => _updateOrderStatus(order, MedicineOrderStatus.delivered),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 3: SHOP PROFILE =================
  Widget _buildProfileTab(ThemeData theme, AuthService auth) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.storefront, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  _profile?.shopName ?? 'Pharmacy Store',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  _profile?.ownerName != null ? 'Owner: ${_profile!.ownerName}' : auth.currentUser ?? '',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const Divider(height: 32),
                _buildProfileDetailRow(Icons.phone, 'Contact Phone', _profile?.phoneNumber ?? 'Not provided'),
                const SizedBox(height: 12),
                _buildProfileDetailRow(Icons.location_on, 'Address', _profile?.address ?? 'Not provided'),
                const SizedBox(height: 12),
                _buildProfileDetailRow(Icons.badge, 'Drug License No.', _profile?.licenseNumber ?? 'Not provided'),
                const SizedBox(height: 12),
                _buildProfileDetailRow(Icons.receipt, 'GST / Tax ID', _profile?.gstNumber ?? 'Not provided'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Shop Details'),
                  onPressed: () => _showEditShopProfileDialog(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  void _showEditShopProfileDialog() {
    final shopNameCtrl = TextEditingController(text: _profile?.shopName ?? '');
    final ownerNameCtrl = TextEditingController(text: _profile?.ownerName ?? '');
    final phoneCtrl = TextEditingController(text: _profile?.phoneNumber ?? '');
    final addressCtrl = TextEditingController(text: _profile?.address ?? '');
    final licCtrl = TextEditingController(text: _profile?.licenseNumber ?? '');
    final gstCtrl = TextEditingController(text: _profile?.gstNumber ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Pharmacy Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: shopNameCtrl,
                decoration: const InputDecoration(labelText: 'Shop / Pharmacy Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ownerNameCtrl,
                decoration: const InputDecoration(labelText: 'Owner Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Contact Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Shop Address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: licCtrl,
                decoration: const InputDecoration(labelText: 'Drug License Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gstCtrl,
                decoration: const InputDecoration(labelText: 'GST Number', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final shopName = shopNameCtrl.text.trim();
              if (shopName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shop Name is required.'), backgroundColor: Colors.red),
                );
                return;
              }

              Navigator.pop(ctx);
              final updated = await _shopService.savePharmacyProfile({
                'shopName': shopName,
                'ownerName': ownerNameCtrl.text.trim(),
                'phoneNumber': phoneCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
                'licenseNumber': licCtrl.text.trim(),
                'gstNumber': gstCtrl.text.trim(),
              });

              if (!mounted) return;
              if (updated != null) {
                setState(() => _profile = updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pharmacy profile updated!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
