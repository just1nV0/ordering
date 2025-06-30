import 'package:flutter/material.dart';
import '../api_helpers/sqlite/insert_sqlite.dart';
import '../api_helpers/sqlite/read_sqlite.dart';

class OrderingScreen extends StatefulWidget {
  const OrderingScreen({Key? key}) : super(key: key);

  @override
  State<OrderingScreen> createState() => _OrderingScreenState();
}

class _OrderingScreenState extends State<OrderingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DBReader _dbReader = DBReader();

  int cartItemCount = 0;
  bool isGridView = true; // Track current view mode
  Set<String> addedItems = {}; // Track which items have been added
  List<MenuItem> menuItems = []; // Will be populated from database
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    try {
      final List<Map<String, dynamic>> items = await _dbReader.readTable(
        tableName: 'itemnames',
        columns: ['ctr', 'itemname', 'uom', 'sold_count'],
        orderBy: 'sold_count DESC',
      );

      print("item.values");
      for (var item in items) {
        print(item.values);
      }

      setState(() {
        menuItems = items
            .map(
              (item) => MenuItem(
                id: item['ctr']?.toString() ?? '',
                name: item['itemname']?.toString() ?? 'Unknown Item',
                price: 0.00,
                uom: item['uom']?.toString() ?? '',
                image:
                    'https://via.placeholder.com/150x150/F5F5F5/9E9E9E?text=${Uri.encodeComponent(item['itemname']?.toString() ?? 'Item')}',
              ),
            )
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading menu items: $e');
      setState(() {
        isLoading = false;
      });
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading menu items: $e'),
            backgroundColor: const Color(0xFF424242), // Dark grey for errors
          ),
        );
      }
    }
  }

  void _addToCart(MenuItem item) {
    setState(() {
      cartItemCount++;
      addedItems.add(item.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF212121), // Dark grey for success
      ),
    );
  }

  void _toggleView() {
    setState(() {
      isGridView = !isGridView;
    });
    Navigator.pop(context); // Close drawer after toggling
  }

  void _viewCart() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Cart',
            style: TextStyle(
              color: Color(0xFF212121),
              fontWeight: FontWeight.w500,
            ),
          ),
          content: Text(
            'You have $cartItemCount items in your cart',
            style: const TextStyle(color: Color(0xFF757575)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9E9E9E),
              ),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF212121),
                backgroundColor: const Color(0xFFF5F5F5),
              ),
              child: const Text('Checkout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Menu',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF212121),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: _viewCart,
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF212121),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFF5F5F5),
                    child: Icon(
                      Icons.person_outline,
                      size: 30,
                      color: Color(0xFF757575),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Welcome',
                    style: TextStyle(
                      color: Color(0xFF212121),
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.home_outlined, 'Home'),
            _buildDrawerItem(Icons.restaurant_menu_outlined, 'Menu'),
            _buildDrawerItem(
              isGridView ? Icons.view_list_outlined : Icons.grid_view_outlined,
              isGridView ? 'List View' : 'Grid View',
              onTap: _toggleView,
            ),
            _buildDrawerItem(Icons.refresh_outlined, 'Refresh Menu', onTap: () {
              Navigator.pop(context);
              setState(() {
                isLoading = true;
              });
              _loadMenuItems();
            }),
            _buildDrawerItem(Icons.history_outlined, 'Order History'),
            _buildDrawerItem(Icons.favorite_outline, 'Favorites'),
            _buildDrawerItem(Icons.person_outline, 'Profile'),
            const Divider(color: Color(0xFFE0E0E0), height: 32),
            _buildDrawerItem(Icons.settings_outlined, 'Settings'),
            _buildDrawerItem(Icons.help_outline, 'Help & Support'),
            _buildDrawerItem(Icons.logout_outlined, 'Logout'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF9E9E9E),
                  strokeWidth: 2,
                ),
              )
            : menuItems.isEmpty
            ? const Center(
                child: Text(
                  'No items available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              )
            : isGridView
            ? GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return MenuItemTile(
                    item: item,
                    onAddToCart: () => _addToCart(item),
                    isAdded: addedItems.contains(item.id),
                  );
                },
              )
            : ListView.builder(
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return MenuItemListTile(
                    item: item,
                    onAddToCart: () => _addToCart(item),
                    isAdded: addedItems.contains(item.id),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF757575),
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF424242),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap ?? () => Navigator.pop(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}

class MenuItemTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onAddToCart;
  final bool isAdded;

  const MenuItemTile({
    Key? key,
    required this.item,
    required this.onAddToCart,
    required this.isAdded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: const Icon(
                Icons.crop_square,
                size: 48,
                color: Color(0xFFE0E0E0),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212121),
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.uom.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.uom,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF424242),
                        ),
                      ),
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isAdded 
                                ? const Color(0xFF212121) 
                                : const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            isAdded ? Icons.check : Icons.add,
                            color: isAdded 
                                ? Colors.white 
                                : const Color(0xFF757575),
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
    );
  }
}

class MenuItemListTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onAddToCart;
  final bool isAdded;

  const MenuItemListTile({
    Key? key,
    required this.item,
    required this.onAddToCart,
    required this.isAdded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
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
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.crop_square,
                size: 24,
                color: Color(0xFFE0E0E0),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212121),
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (item.uom.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.uom,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '₱${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onAddToCart,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAdded 
                      ? const Color(0xFF212121) 
                      : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isAdded ? Icons.check : Icons.add,
                  color: isAdded 
                      ? Colors.white 
                      : const Color(0xFF757575),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItem {
  final String id;
  final String name;
  final double price;
  final String uom;
  final String image;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.uom,
    required this.image,
  });
}