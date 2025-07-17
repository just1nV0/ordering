import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../theme/app_color_palette.dart';

class ViewItemScreen extends StatefulWidget {
  final MenuItem item;
  final AppColorPalette theme;
  final bool isInCart;
  final Function(MenuItem, int)? onAddToCart; 
  final VoidCallback? onRemoveFromCart;
  final int initialQuantity;

  const ViewItemScreen({
    Key? key,
    required this.item,
    required this.theme,
    this.isInCart = false,
    this.onAddToCart,
    this.onRemoveFromCart,
    this.initialQuantity = 1, 
  }) : super(key: key);

  @override
  State<ViewItemScreen> createState() => _ViewItemScreenState();
}

class _ViewItemScreenState extends State<ViewItemScreen> with TickerProviderStateMixin {
  late int quantity; 
  bool isFavorite = false;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    quantity = widget.initialQuantity;
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    setState(() {
      quantity++;
    });
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: widget.theme.success,
      ),
    );
  }

  void _addToCart() {
    if (widget.onAddToCart != null) {
      widget.onAddToCart!(widget.item, quantity);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$quantity ${widget.item.name}${quantity > 1 ? 's' : ''} added to cart'),
        duration: const Duration(seconds: 2),
        backgroundColor: widget.theme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildItemHeader(),
                      const SizedBox(height: 24),
                      _buildPriceSection(),
                      const SizedBox(height: 24),
                      _buildDescriptionSection(),
                      const SizedBox(height: 24),
                      _buildSpecificationsSection(),
                      const SizedBox(height: 24),
                      _buildQuantitySection(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: widget.theme.primary,
      foregroundColor: widget.theme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.theme.primary,
                widget.theme.primaryLight,
              ],
            ),
          ),
          child: Center(
            child: Hero(
              tag: 'item-${widget.item.id}',
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: widget.theme.surface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.theme.surface.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.eco_outlined,
                  size: 80,
                  color: widget.theme.surface,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? widget.theme.accent : widget.theme.surface,
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Share feature coming soon'),
                backgroundColor: widget.theme.textTertiary,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildItemHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.item.name,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: widget.theme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        if (widget.item.uom.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.theme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.theme.border,
                width: 1,
              ),
            ),
            child: Text(
              widget.item.uom,
              style: TextStyle(
                fontSize: 14,
                color: widget.theme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.theme.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.theme.textTertiary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price',
                style: TextStyle(
                  fontSize: 16,
                  color: widget.theme.textTertiary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₱${widget.item.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: widget.theme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (widget.isInCart)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.theme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.theme.success,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: widget.theme.success,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'In Cart',
                    style: TextStyle(
                      color: widget.theme.success,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.theme.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.theme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Fresh and high-quality ${widget.item.name.toLowerCase()}. Carefully selected and prepared to ensure the best taste and nutritional value. Perfect for your daily meals and healthy lifestyle.',
            style: TextStyle(
              fontSize: 16,
              color: widget.theme.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.theme.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.theme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpecRow('Category', 'Fresh Produce'),
          _buildSpecRow('Unit of Measure', widget.item.uom.isNotEmpty ? widget.item.uom : 'Piece'),
          _buildSpecRow('Storage', 'Keep refrigerated'),
          _buildSpecRow('Shelf Life', '3-7 days'),
          _buildSpecRow('Origin', 'Local Farm'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: widget.theme.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: widget.theme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.theme.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Quantity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.theme.textPrimary,
            ),
          ),
          Row(
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onPressed: _decrementQuantity,
                enabled: quantity > 1,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.theme.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  '$quantity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.theme.textPrimary,
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onPressed: _incrementQuantity,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled ? widget.theme.primary : widget.theme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.theme.border,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? widget.theme.surface : widget.theme.textTertiary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primary,
              foregroundColor: widget.theme.surface,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isInCart ? Icons.refresh : Icons.add_shopping_cart,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.isInCart ? 'Update Cart' : 'Add to Cart',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '₱${(widget.item.price * quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.theme.textSecondary,
              side: BorderSide(
                color: widget.theme.border,
                width: 1,
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Back to Menu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}