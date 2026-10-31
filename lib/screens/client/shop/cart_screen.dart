import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/prescription.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../services/medical_shop_service.dart';
import '../../../routes/app_routes.dart';
import '../../../core/responsive.dart';
import '../../../core/image_helper.dart';

class CartScreen extends StatefulWidget {
  final String? patientEmail;

  const CartScreen({super.key, this.patientEmail});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final MedicalShopService _shopService = MedicalShopService();

  List<Prescription> _prescriptions = [];
  int? _selectedPrescriptionId;
  bool _isLoadingPrescriptions = false;
  String? _prescriptionError;
  bool _isSubmitting = false;
  String? _uploadedPrescriptionImage;

  Future<void> _openUploadPrescription() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.uploadPrescription,
    );
    if (result != null && result is String && result.isNotEmpty) {
      if (mounted) {
        setState(() {
          _uploadedPrescriptionImage = result;
        });
        context.read<CartProvider>().setUploadedPrescriptionImage(result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription attached to order successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<Prescription> _matchingPrescriptions(CartProvider cart) {
    final names = cart.itemList
        .where((item) => item.medicine.requiresPrescription)
        .map((item) => item.medicine.medicineName.trim().toLowerCase())
        .toSet();
    return _prescriptions
        .where((p) =>
            p.isActive &&
            (p.shopMedicineId == null ||
                cart.itemList
                    .any((item) => item.medicine.id == p.shopMedicineId)) &&
            names.contains(p.medicineName.trim().toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _uploadedPrescriptionImage =
        context.read<CartProvider>().uploadedPrescriptionImage;
    _loadInitialData();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final auth = context.read<AuthService>();
    final currentEmail = auth.currentUser;

    // Load profile address
    final profile = await DatabaseService().getUserProfileData();
    if (profile?.address != null && profile!.address!.isNotEmpty) {
      _addressController.text = profile.address!;
    }

    // Load active prescriptions
    if (mounted) setState(() => _isLoadingPrescriptions = true);
    try {
      final patientId = widget.patientEmail ?? currentEmail;
      if (patientId != null) {
        final list = await _shopService.getPrescriptionsForPatient(patientId);
        if (mounted) {
          setState(() {
            _prescriptions = list;
            _prescriptionError = null;
            if (list.isNotEmpty) {
              _selectedPrescriptionId = list.first.id;
            }
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _prescriptionError =
              'Unable to load prescriptions. Check your connection and retry.';
        });
      }
    }
    if (mounted) {
      setState(() => _isLoadingPrescriptions = false);
    }
  }

  Future<void> _handleCheckout(CartProvider cart, AuthService auth) async {
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a delivery address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final hasValidPrescription = _uploadedPrescriptionImage != null ||
        _matchingPrescriptions(cart)
            .any((p) => p.id == _selectedPrescriptionId);

    if (cart.requiresPrescription && !hasValidPrescription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'One or more medicines require a valid doctor prescription. Please select or upload one.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final effectivePatientId = widget.patientEmail ?? auth.currentUser;
    if (effectivePatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to identify patient.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final order = await cart.checkout(
        patientId: effectivePatientId,
        deliveryAddress: address,
        prescriptionId: _selectedPrescriptionId,
        prescriptionImage: _uploadedPrescriptionImage,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (order != null) {
        setState(() { _uploadedPrescriptionImage = null; });
        context.read<CartProvider>().setUploadedPrescriptionImage(null);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Order Placed!'),
              ],
            ),
            content: Text(
              'Your order #${order.id} has been submitted successfully to ${order.shopName ?? 'the medical shop'}.\n\nYou can track the status in the My Orders tab.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to place order. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthService>();
    final isCaretaker = auth.isCaretaker;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear Cart',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text(
                        'Are you sure you want to remove all items from your cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          cart.clear();
                          Navigator.pop(ctx);
                        },
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add medicines from the catalog to place an order.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.storefront),
                    label: const Text('Browse Catalog'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            )
          : Center(
              child: ResponsiveContentWrapper(
                maxWidth: 800,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Patient notice for Caretaker
                    if (isCaretaker)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ordering for patient: ${widget.patientEmail ?? 'Active Patient'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Items list
                    Text(
                      'Order Items (${cart.itemCount})',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...cart.itemList.map((item) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.medication,
                                    color: theme.colorScheme.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.medicine.medicineName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${item.medicine.price.toStringAsFixed(2)} each',
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12),
                                    ),
                                    if (item.medicine.requiresPrescription)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Prescription Required',
                                          style: TextStyle(
                                              color: Colors.deepPurple.shade700,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Qty controls
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 20),
                                    onPressed: () =>
                                        cart.decrementItem(item.medicine.id),
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline,
                                        size: 20),
                                    onPressed: () {
                                      if (item.quantity <
                                          item.medicine.stockQuantity) {
                                        cart.addItem(item.medicine);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Max stock limit reached.')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                '₹${item.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Prescription Selection if needed
                    if (cart.requiresPrescription) ...[
                      Builder(builder: (context) {
                        final matching = _matchingPrescriptions(cart);
                        return Card(
                          color:
                              Colors.deepPurple.shade50.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.deepPurple.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.medical_services_outlined,
                                        color: Colors.deepPurple),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Doctor Prescription Required',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple.shade900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Your cart includes prescription medications. Please attach a valid prescription issued by your doctor.',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black87),
                                ),
                                const SizedBox(height: 12),
                                if (_uploadedPrescriptionImage != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey.shade200,
                                            child: AppImageHelper.getImageProvider(_uploadedPrescriptionImage) != null
                                                ? Image(
                                                    image: AppImageHelper.getImageProvider(_uploadedPrescriptionImage)!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(Icons.receipt_long, color: Colors.green),
                                                  )
                                                : const Icon(Icons.receipt_long, color: Colors.green),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Prescription Attached',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green.shade900,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Doctor prescription image will be included with order',
                                                style: TextStyle(
                                                  color: Colors.green.shade800,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 20),
                                          tooltip: 'Change prescription',
                                          onPressed: _openUploadPrescription,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 20, color: Colors.red),
                                          tooltip: 'Remove',
                                          onPressed: () {
                                            setState(() {
                                              _uploadedPrescriptionImage = null;
                                            });
                                            context.read<CartProvider>().setUploadedPrescriptionImage(null);
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                else if (_isLoadingPrescriptions)
                                  const Center(
                                      child: CircularProgressIndicator())
                                else if (_prescriptionError != null &&
                                    _prescriptions.isEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(_prescriptionError!,
                                          style: const TextStyle(
                                              color: Colors.red, fontSize: 12)),
                                      TextButton.icon(
                                        onPressed: _loadInitialData,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry'),
                                      ),
                                    ],
                                  )
                                else if (matching.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade50.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.deepPurple.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'No active digital prescription found for medicines in this cart.',
                                          style: TextStyle(
                                              color: Colors.deepPurple, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Upload a photo of your doctor\'s prescription to complete this order.',
                                          style: TextStyle(
                                              color: Colors.grey.shade700, fontSize: 12),
                                        ),
                                        const SizedBox(height: 10),
                                        ElevatedButton.icon(
                                          onPressed: _openUploadPrescription,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.colorScheme.primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          icon: const Icon(Icons.upload_file, size: 18),
                                          label: const Text('Request prescription from doc'),
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  DropdownButtonFormField<int>(
                                    initialValue: matching.any((p) =>
                                            p.id == _selectedPrescriptionId)
                                        ? _selectedPrescriptionId
                                        : null,
                                    decoration: const InputDecoration(
                                      labelText: 'Select Prescription',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                    items: matching.map((p) {
                                      return DropdownMenuItem(
                                        value: p.id,
                                        child: Text(
                                          'Dr. ${p.doctorName ?? 'Doctor'} - ${p.medicineName} (${p.diagnosis ?? 'Prescription'})',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedPrescriptionId = val;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: _openUploadPrescription,
                                      icon: const Icon(Icons.upload_file, size: 16),
                                      label: const Text('Or upload prescription image from doctor'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // Delivery Info
                    Text(
                      'Delivery Details',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Address *',
                        hintText:
                            'Enter full street address, apartment, and city',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Special Delivery Instructions (Optional)',
                        hintText: 'e.g. Leave with security, call upon arrival',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bill Summary
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Items Total'),
                                Text('₹${cart.totalAmount.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Delivery Fee'),
                                Text('FREE',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Payable',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(
                                  '₹${cart.totalAmount.toStringAsFixed(2)}',
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
                    const SizedBox(height: 24),

                    // Checkout Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () => _handleCheckout(cart, auth),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                'Place Order (₹${cart.totalAmount.toStringAsFixed(2)})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
