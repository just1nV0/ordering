import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';

class CartDialog extends StatelessWidget {
  final AppColorPalette theme;
  final int cartItemCount;

  const CartDialog({
    Key? key,
    required this.theme,
    required this.cartItemCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: theme.surface,
      title: Text(
        'Cart',
        style: TextStyle(
          color: theme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      content: Text(
        'You have $cartItemCount items in your cart',
        style: TextStyle(color: theme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: theme.textTertiary,
          ),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Add checkout functionality here
          },
          style: TextButton.styleFrom(
            foregroundColor: theme.surface,
            backgroundColor: theme.primary,
          ),
          child: const Text('Checkout'),
        ),
      ],
    );
  }
}