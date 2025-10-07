// import 'package:flutter/material.dart';
// import '../models/menu_item.dart';
// import '../models/cart_item.dart';
// import '../theme/app_color_palette.dart';

// class CartScreen extends StatefulWidget {
//   final AppColorPalette theme;
//   final List<CartItem> cartItems;
//   final VoidCallback? onCheckoutComplete;
//   final Function(List<CartItem>)? onCartUpdated;
  
//   const CartScreen({
//     Key? key,
//     required this.theme,
//     required this.cartItems,
//     this.onCheckoutComplete,
//     this.onCartUpdated,
//   }) : super(key: key);

//   @override
//   State<CartScreen> createState() => _CartScreenState();
// }

// class _CartScreenState extends State<CartScreen> {
//   late List<CartItem> _cartItems;
  
//   @override
//   void initState() {
//     super.initState();
//     _cartItems = List.from(widget.cartItems);
//   }
  
//   double get subtotal {
//     return _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
//   }
  
//   double get tax {
//     return subtotal * 0.12; 
//   }
  
//   double get total {
//     return subtotal + tax;
//   }
  
//   void _updateQuantity(int index, int newQuantity) {
//     if (newQuantity <= 0) {
//       _removeItem(index);
//     } else {
//       setState(() {
//         _cartItems[index].quantity = newQuantity;
//       });
//       if (widget.onCartUpdated != null) {
//         widget.onCartUpdated!(_cartItems);
//       }
//     }
//   }
  
//   void _removeItem(int index) {
//     setState(() {
//       _cartItems.removeAt(index);
//     });
//     if (widget.onCartUpdated != null) {
//       widget.onCartUpdated!(_cartItems);
//     }
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text('Item removed from cart'),
//         backgroundColor: widget.theme.error,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }
  
//   void _clearCart() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) => AlertDialog(
//         backgroundColor: widget.theme.surface,
//         title: Text(
//           'Clear Cart',
//           style: TextStyle(color: widget.theme.textPrimary),
//         ),
//         content: Text(
//           'Are you sure you want to remove all items from your cart?',
//           style: TextStyle(color: widget.theme.textSecondary),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               'Cancel',
//               style: TextStyle(color: widget.theme.textSecondary),
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               setState(() {
//                 _cartItems.clear();
//               });
//               if (widget.onCartUpdated != null) {
//                 widget.onCartUpdated!(_cartItems);
//               }
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: const Text('Cart cleared'),
//                   backgroundColor: widget.theme.success,
//                 ),
//               );
//             },
//             child: Text(
//               'Clear',
//               style: TextStyle(color: widget.theme.error),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
  
//   void _proceedToCheckout() {
//     if (_cartItems.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Your cart is empty'),
//           backgroundColor: widget.theme.error,
//         ),
//       );
//       return;
//     }
    
//     showDialog(
//       context: context,
//       builder: (BuildContext context) => AlertDialog(
//         backgroundColor: widget.theme.surface,
//         title: Text(
//           'Order Confirmed',
//           style: TextStyle(color: widget.theme.textPrimary),
//         ),
//         content: Text(
//           'Your order has been placed successfully!\nTotal: ₱${total.toStringAsFixed(2)}',
//           style: TextStyle(color: widget.theme.textSecondary),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context); 
//               Navigator.pop(context);
//               setState(() {
//                 _cartItems.clear();
//               });
//               if (widget.onCheckoutComplete != null) {
//                 widget.onCheckoutComplete!();
//               }
//             },
//             child: Text(
//               'OK',
//               style: TextStyle(color: widget.theme.primary),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: widget.theme.background,
//       appBar: AppBar(
//         title: Text(
//           'Cart (${_cartItems.length})',
//           style: TextStyle(
//             fontWeight: FontWeight.w400,
//             letterSpacing: 0.5,
//             color: widget.theme.textPrimary,
//           ),
//         ),
//         backgroundColor: widget.theme.surface,
//         foregroundColor: widget.theme.textPrimary,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//         actions: [
//           if (_cartItems.isNotEmpty)
//             IconButton(
//               icon: const Icon(Icons.delete_outline),
//               onPressed: _clearCart,
//               tooltip: 'Clear cart',
//             ),
//         ],
//       ),
//       body: _cartItems.isEmpty ? _buildEmptyCart() : _buildCartContent(),
//       bottomNavigationBar: _cartItems.isNotEmpty ? _buildBottomBar() : null,
//     );
//   }
  
//   Widget _buildEmptyCart() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.shopping_cart_outlined,
//             size: 80,
//             color: widget.theme.textTertiary,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Your cart is empty',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w500,
//               color: widget.theme.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Add some items from the menu',
//             style: TextStyle(
//               fontSize: 14,
//               color: widget.theme.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: widget.theme.primary,
//               foregroundColor: widget.theme.surface,
//               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text('Browse Menu'),
//           ),
//         ],
//       ),
//     );
//   }
  
//   Widget _buildCartContent() {
//     return Column(
//       children: [
//         Expanded(
//           child: ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: _cartItems.length,
//             itemBuilder: (context, index) {
//               final cartItem = _cartItems[index];
//               return _buildCartItemCard(cartItem, index);
//             },
//           ),
//         ),
//         _buildOrderSummary(),
//       ],
//     );
//   }
  
//   Widget _buildCartItemCard(CartItem cartItem, int index) {
//     return Card(
//       color: widget.theme.surface,
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Container(
//               width: 60,
//               height: 60,
//               decoration: BoxDecoration(
//                 color: widget.theme.background,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 Icons.fastfood,
//                 color: widget.theme.textTertiary,
//                 size: 24,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     cartItem.menuItem.name,
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: widget.theme.textPrimary,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     cartItem.menuItem.uom,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: widget.theme.textSecondary,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     '₱${cartItem.menuItem.price.toStringAsFixed(2)}',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: widget.theme.primary,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Column(
//               children: [
//                 Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(
//                       onPressed: () => _updateQuantity(index, cartItem.quantity - 1),
//                       icon: const Icon(Icons.remove),
//                       color: widget.theme.textSecondary,
//                       constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
//                       padding: EdgeInsets.zero,
//                     ),
//                     Container(
//                       width: 40,
//                       height: 32,
//                       alignment: Alignment.center,
//                       decoration: BoxDecoration(
//                         color: widget.theme.background,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: Text(
//                         '${cartItem.quantity}',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                           color: widget.theme.textPrimary,
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: () => _updateQuantity(index, cartItem.quantity + 1),
//                       icon: const Icon(Icons.add),
//                       color: widget.theme.textSecondary,
//                       constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
//                       padding: EdgeInsets.zero,
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   '₱${cartItem.totalPrice.toStringAsFixed(2)}',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: widget.theme.textPrimary,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildOrderSummary() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: widget.theme.surface,
//         border: Border(
//           top: BorderSide(
//             color: widget.theme.border,
//             width: 1,
//           ),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Text(
//             'Order Summary',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: widget.theme.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 12),
//           _buildSummaryRow('Subtotal', subtotal),
//           _buildSummaryRow('Tax (12%)', tax),
//           const Divider(height: 20),
//           _buildSummaryRow('Total', total, isTotal: true),
//         ],
//       ),
//     );
//   }
  
//   Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: isTotal ? 16 : 14,
//             fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
//             color: widget.theme.textPrimary,
//           ),
//         ),
//         Text(
//           '₱${amount.toStringAsFixed(2)}',
//           style: TextStyle(
//             fontSize: isTotal ? 16 : 14,
//             fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
//             color: isTotal ? widget.theme.primary : widget.theme.textPrimary,
//           ),
//         ),
//       ],
//     );
//   }
  
//   Widget _buildBottomBar() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: widget.theme.surface,
//         border: Border(
//           top: BorderSide(
//             color: widget.theme.border,
//             width: 1,
//           ),
//         ),
//       ),
//       child: SafeArea(
//         child: ElevatedButton(
//           onPressed: _proceedToCheckout,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: widget.theme.primary,
//             foregroundColor: widget.theme.surface,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             elevation: 2,
//           ),
//           child: Text(
//             'Proceed to Checkout - ₱${total.toStringAsFixed(2)}',
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }