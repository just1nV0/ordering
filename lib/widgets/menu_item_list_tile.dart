import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../theme/app_color_palette.dart';
import 'view_item_screen.dart';

class MenuItemListTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onAddToCart;
  final bool isAdded;
  final AppColorPalette theme;

  const MenuItemListTile({
    Key? key,
    required this.item,
    required this.onAddToCart,
    required this.isAdded,
    required this.theme,
  }) : super(key: key);

  @override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewItemScreen(
            item: item,
            theme: theme,
            isInCart: isAdded,
            onAddToCart: onAddToCart,
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.border,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.eco_outlined,
                size: 24,
                color: theme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (item.uom.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.uom,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '₱${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                // This will only trigger the add to cart action
                onAddToCart();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAdded ? theme.primary : theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.border,
                    width: 1,
                  ),
                ),
                child: Icon(
                  isAdded ? Icons.check : Icons.add,
                  color: isAdded ? theme.surface : theme.textTertiary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}