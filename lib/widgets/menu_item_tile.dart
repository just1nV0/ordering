import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../theme/app_color_palette.dart';
import '../screens/view_item_screen.dart';

class MenuItemTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onAddToCart;
  final Function(MenuItem, int)? onAddToCartWithQuantity;
  final bool isAdded;
  final AppColorPalette theme;
  final int currentQuantity; 

  const MenuItemTile({
    Key? key,
    required this.item,
    required this.onAddToCart,
    this.onAddToCartWithQuantity,
    required this.isAdded,
    required this.theme,
    this.currentQuantity = 1,
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
  initialQuantity: currentQuantity,
                onAddToCart: onAddToCartWithQuantity ?? (item, quantity) {
                  for (int i = 0; i < quantity; i++) {
                    onAddToCart.call();
                  }
                },
              ),
            ),
          );
    },
    child:  Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Icon(
                Icons.eco_outlined,
                size: 48,
                color: theme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.textPrimary,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.uom.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.uom,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: theme.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          padding: const EdgeInsets.all(8),
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
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
  }
