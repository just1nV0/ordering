import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ordering/api_helpers/google_sheets/crud/read_sheets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../theme/app_color_palette.dart';
import '../api_helpers/google_sheets/crud/write_sheets.dart';

class CartWidget extends StatefulWidget {
  final AppColorPalette theme;
  final List<CartItem> cartItems;
  final VoidCallback? onCheckoutComplete;
  final Function(List<CartItem>)? onCartUpdated;

  const CartWidget({
    Key? key,
    required this.theme,
    required this.cartItems,
    this.onCheckoutComplete,
    this.onCartUpdated,
  }) : super(key: key);

  @override
  State<CartWidget> createState() => _CartWidgetState();
}

class _CartWidgetState extends State<CartWidget> {
  late List<CartItem> _cartItems;
  bool _isProcessingCheckout = false;
  static const String _spreadsheetId = '1uuQtJKa7NngVjHEbV2wsq4BaEOAbKPPeLf2L5NObCcU';
  static const String _serviceAccountAssetPath = 'assets/service_account.json';

  @override
  void initState() {
    super.initState();
    _cartItems = List.from(widget.cartItems);
  }

  double get subtotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get tax => subtotal * 0.12;
  double get total => subtotal + tax;

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      setState(() => _cartItems.removeAt(index));
    } else {
      setState(() => _cartItems[index].quantity = newQuantity);
    }
    widget.onCartUpdated?.call(_cartItems);
  }

 Future<void> _processCheckout() async {
  if (_cartItems.isEmpty || _isProcessingCheckout) return;

  setState(() {
    _isProcessingCheckout = true;
  });

  try {
    print('🔍 Debug Info:');
    print('   Spreadsheet ID: $_spreadsheetId');
    print('   Service Account Path: $_serviceAccountAssetPath');
    print('   Cart items count: ${_cartItems.length}');

    final DateTime now = DateTime.now();
    final String formattedDateTime = 
        '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final sheetsReader = SheetsReader();
    await sheetsReader.initialize(
      spreadsheetId: _spreadsheetId,
      serviceAccountJsonAssetPath: _serviceAccountAssetPath,
    );

    final existingOrders = await sheetsReader.readSheetAsMapList(
      sheetName: 'orders',
      range: 'A:Z',
      firstRowIsHeader: true,
    );

    int nextCtr = 1;
    if (existingOrders != null && existingOrders.isNotEmpty) {
      final ctrValues = existingOrders
          .where((row) => row.containsKey('ctr') && row['ctr'] != null)
          .map((row) => int.tryParse(row['ctr'].toString()) ?? 0)
          .toList();

      if (ctrValues.isNotEmpty) {
        nextCtr = ctrValues.reduce((a, b) => a > b ? a : b) + 1;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final userInfoString = prefs.getString('user_info');
    Map<String, dynamic> userInfo = {};
    if (userInfoString != null) {
      try {
        userInfo = jsonDecode(userInfoString);
      } catch (e) {
        print('⚠️ Failed to parse user_info: $e');
      }
    }

    final customerId = userInfo['ctr'] ?? '';
    try {
      await SheetsWriter.createSheetIfNotExists(
        spreadsheetId: _spreadsheetId,
        serviceAccountJsonAssetPath: _serviceAccountAssetPath,
        sheetName: 'orders',
      );
      print('✅ Sheet verification/creation completed');
    } catch (e) {
      print('⚠️ Sheet creation check failed: $e');
    }

    for (int i = 0; i < _cartItems.length; i++) {
      final CartItem cartItem = _cartItems[i];
      if (cartItem.quantity <= 0) continue;

      final List<Object?> rowValues = [
        nextCtr++, 
        formattedDateTime,  
        cartItem.quantity,  
        cartItem.menuItem.id,
        cartItem.menuItem.name,
        customerId,  
        cartItem.menuItem.price,
        cartItem.totalPrice,
      ];

      print('📝 Inserting row ${i + 1}: $rowValues');

      await SheetsWriter.appendRow(
        spreadsheetId: _spreadsheetId,
        serviceAccountJsonAssetPath: _serviceAccountAssetPath,
        sheetName: 'orders',
        rowValues: rowValues,
      );

      print('✅ Successfully inserted row ${i + 1}');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order placed successfully!'),
          backgroundColor: widget.theme.success,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    setState(() => _cartItems.clear());
    widget.onCheckoutComplete?.call();

  } catch (e) {
    print('❌ Checkout failed: $e');
    print('Stack trace: ${StackTrace.current}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: ${e.toString()}'),
          backgroundColor: widget.theme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isProcessingCheckout = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    if (_cartItems.isEmpty) return _buildEmptyCart();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final cartItem = _cartItems[index];
              return _itemCard(cartItem, index);
            },
          ),
        ),
        _buildSummaryAndCheckout(),
      ],
    );
  }

  Widget _buildEmptyCart() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shopping_cart_outlined,
          size: 80,
          color: widget.theme.textTertiary,
        ),
        const SizedBox(height: 16),
        Text(
          'Your cart is empty',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: widget.theme.textPrimary,
          ),
        ),
      ],
    ),
  );

  Widget _itemCard(CartItem cartItem, int index) => Card(
    color: widget.theme.surface,
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: widget.theme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.fastfood,
              color: widget.theme.textTertiary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.menuItem.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cartItem.menuItem.uom,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₱${cartItem.menuItem.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.theme.primary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () =>
                        _updateQuantity(index, cartItem.quantity - 1),
                    icon: const Icon(Icons.remove),
                    color: widget.theme.textSecondary,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  Container(
                    width: 40,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.theme.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${cartItem.quantity}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: widget.theme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        _updateQuantity(index, cartItem.quantity + 1),
                    icon: const Icon(Icons.add),
                    color: widget.theme.textSecondary,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '₱${cartItem.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildSummaryAndCheckout() => Container(
    padding: const EdgeInsets.all(16),
    color: widget.theme.surface,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Total"),
            Text(
              "₱${total.toStringAsFixed(2)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.theme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isProcessingCheckout ? null : _processCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.theme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isProcessingCheckout
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.theme.surface,
                    ),
                  ),
                )
              : const Text(
                  "Checkout",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    ),
  );
}