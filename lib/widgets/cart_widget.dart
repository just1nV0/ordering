import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../theme/app_color_palette.dart';

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
          onPressed: () {
            setState(() => _cartItems.clear());
            widget.onCheckoutComplete?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.theme.primary,
          ),
          child: const Text("Checkout"),
        ),
      ],
    ),
  );
}
