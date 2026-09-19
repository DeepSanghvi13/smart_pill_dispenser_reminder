import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/medicine_order.dart';
import '../../../models/shop_medicine.dart';
import '../../../providers/cart_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/medical_shop_service.dart';

import 'package:flutter_typeahead/flutter_typeahead.dart';

class MedicalShopScreen extends StatefulWidget {
  const MedicalShopScreen({super.key});

  @override
  State<MedicalShopScreen> createState() => _MedicalShopScreenState();
}

class _MedicalShopScreenState extends State<MedicalShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final MedicalShopService _shopService = MedicalShopService();

  List<ShopMedicine> _catalog = [];
  List<MedicineOrder> _myOrders = [];
  bool _isLoadingCatalog = false;
  bool _isLoadingOrders = false;
  String _selectedCategory = 'All';
  String? _caretakerSelectedPatientEmail;

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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _loadOrders();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.isCaretaker) {
        final patients = auth.getConnectedPatients();
        if (patients.isNotEmpty) {
          setState(() {
            _caretakerSelectedPatientEmail = patients.first.email;
          });
        }
      }
      _loadCatalog();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() => _isLoadingCatalog = true);
    try {
      final items = await _shopService.getCatalog(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _catalog = items;
          _isLoadingCatalog = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCatalog = false);
      }
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final orders = await _shopService.getMyOrders();
      if (mounted) {
        setState(() {
          _myOrders = orders;
          _isLoadingOrders = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingOrders = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthService>();
    final isCaretaker = auth.isCaretaker;
    final connectedPatients = auth.getConnectedPatients();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Shop'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.storefront_outlined), text: 'Catalog'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'My Orders'),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: cart.itemCount > 0,
              label: Text('${cart.itemCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.cart,
                arguments: _caretakerSelectedPatientEmail,
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Catalog
          RefreshIndicator(
            onRefresh: _loadCatalog,
            child: Column(
              children: [
                // Caretaker patient selector banner
                if (isCaretaker)
                  Container(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.person_pin, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Ordering for: ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: connectedPatients.isEmpty
                              ? const Text(
                                  'No patients connected',
                                  style: TextStyle(color: Colors.red, fontSize: 12),
                                )
                              : DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _caretakerSelectedPatientEmail,
                                    isExpanded: true,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    items: connectedPatients.map((p) {
                                      return DropdownMenuItem(
                                        value: p.email,
                                        child: Text(p.fullName, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _caretakerSelectedPatientEmail = val;
                                      });
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                // Search Bar with TypeAhead Auto-complete
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TypeAheadField<ShopMedicine>(
                    controller: _searchController,
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Search medicines, generic names...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    controller.clear();
                                    _loadCatalog();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _loadCatalog(),
                      );
                    },
                    suggestionsCallback: (pattern) async {
                      // Call backend to get matching medicines (or all if empty)
                      return await _shopService.getCatalog(search: pattern.trim());
                    },
                    itemBuilder: (context, ShopMedicine suggestion) {
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.medication, color: theme.colorScheme.primary, size: 20),
                        ),
                        title: Text(suggestion.medicineName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${suggestion.category} • ₹${suggestion.price.toStringAsFixed(2)}'),
                        trailing: suggestion.isOutOfStock 
                            ? const Text('Out of Stock', style: TextStyle(color: Colors.red, fontSize: 12))
                            : const Icon(Icons.arrow_forward_ios, size: 14),
                      );
                    },
                    emptyBuilder: (context) => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No matching medicines found.'),
                    ),
                    onSelected: (ShopMedicine suggestion) {
                      // Update search bar text and filter the list exactly to this medicine
                      _searchController.text = suggestion.medicineName;
                      _loadCatalog();
                    },
                  ),
                ),

                // Category Filter Chips
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
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
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                          _loadCatalog();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Catalog Grid / List
                Expanded(
                  child: _isLoadingCatalog
                      ? const Center(child: CircularProgressIndicator())
                      : _catalog.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No medicines available in catalog',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Refresh'),
                                    onPressed: _loadCatalog,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _catalog.length,
                              itemBuilder: (context, index) {
                                final item = _catalog[index];
                                return _buildCatalogItemCard(context, item, cart);
                              },
                            ),
                ),
              ],
            ),
          ),

          // Tab 2: My Orders
          RefreshIndicator(
            onRefresh: _loadOrders,
            child: _isLoadingOrders
                ? const Center(child: CircularProgressIndicator())
                : _myOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No orders placed yet',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                _tabController.animateTo(0);
                              },
                              child: const Text('Start Shopping'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _myOrders.length,
                        itemBuilder: (context, index) {
                          final order = _myOrders[index];
                          return _buildOrderCard(context, order);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: cart.itemCount > 0
          ? FloatingActionButton.extended(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text('View Cart (${cart.itemCount}) • ₹${cart.totalAmount.toStringAsFixed(2)}'),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.cart,
                  arguments: _caretakerSelectedPatientEmail,
                );
              },
            )
          : null,
    );
  }

  Widget _buildCatalogItemCard(BuildContext context, ShopMedicine item, CartProvider cart) {
    final theme = Theme.of(context);
    final isOutOfStock = item.isOutOfStock;
    final isExpired = item.isExpired;
    final canAddToCart = !isOutOfStock && !isExpired;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isExpired
            ? BorderSide(color: Colors.red.shade300, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.medicineName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.category} • ${item.dosage}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      if (item.shopName != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.store, size: 13, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.shopName!,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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
            const SizedBox(height: 12),

            // Badges row
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                // Stock status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isOutOfStock ? 'Out of Stock' : 'In Stock (${item.stockQuantity})',
                    style: TextStyle(
                      color: isOutOfStock ? Colors.red : Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

                // Expiry date badge (DD/MM/YYYY)
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 11,
                        color: isExpired
                            ? Colors.red
                            : (item.isExpiringSoon ? Colors.orange : Colors.blue),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Exp: ${item.formattedExpiryDate}',
                        style: TextStyle(
                          color: isExpired
                              ? Colors.red
                              : (item.isExpiringSoon ? Colors.orange.shade800 : Colors.blue.shade800),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Prescription badge
                if (item.requiresPrescription)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description, size: 11, color: Colors.deepPurple),
                        const SizedBox(width: 4),
                        Text(
                          'Prescription Req.',
                          style: TextStyle(
                            color: Colors.deepPurple.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.manufacturer != null && item.manufacturer!.isNotEmpty)
                  Expanded(
                    child: Text(
                      'Mfg: ${item.manufacturer}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cart.hasItem(item.id))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.remove, size: 16),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              cart.decrementItem(item.id);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${cart.getQuantity(item.id)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          IconButton.filled(
                            icon: const Icon(Icons.add, size: 16),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              if (cart.getQuantity(item.id) < item.stockQuantity) {
                                cart.addItem(item);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cannot add more than available stock.')),
                                );
                              }
                            },
                          ),
                        ],
                      )
                    else
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add_shopping_cart, size: 20),
                        tooltip: 'Add to Cart',
                        onPressed: canAddToCart
                            ? () {
                                cart.addItem(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.medicineName} added to cart'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            : null,
                      ),
                    
                    const SizedBox(width: 8),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAddToCart ? theme.colorScheme.primary : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: canAddToCart
                          ? () {
                              if (!cart.hasItem(item.id)) {
                                cart.addItem(item);
                              }
                              Navigator.pushNamed(
                                context,
                                AppRoutes.cart,
                                arguments: _caretakerSelectedPatientEmail,
                              );
                            }
                          : null,
                      child: const Text('Buy Now', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildOrderCard(BuildContext context, MedicineOrder order) {
    Color statusColor = Colors.orange;
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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.orderDetails,
            arguments: order,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.statusDisplayName,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (order.shopName != null) ...[
                Row(
                  children: [
                    const Icon(Icons.store, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      order.shopName!,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Items: ${order.items.length} • Placed on: ${order.formattedOrderDate}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
