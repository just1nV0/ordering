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
                    'https://via.placeholder.com/150x150/4CAF50/FFFFFF?text=${Uri.encodeComponent(item['itemname']?.toString() ?? 'Item')}',
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
            backgroundColor: const Color(0xFFE57373), // Soft red for errors
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
        backgroundColor: const Color(0xFF4CAF50), // Fresh green for success
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
          backgroundColor: const Color(0xFFF8FFF8), // Very light green background
          title: const Text(
            'Cart',
            style: TextStyle(color: Color(0xFF2E7D32)), // Dark green
          ),
          content: Text(
            'You have $cartItemCount items in your cart',
            style: const TextStyle(color: Color(0xFF424242)), // Dark grey
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF757575), // Medium grey
              ),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50), // Fresh green
                foregroundColor: Colors.white,
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
      appBar: AppBar(
        title: const Text('Fresh Vegetables'),
        backgroundColor: const Color(0xFF4CAF50), // Fresh green
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _viewCart,
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35), // Orange accent
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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)], // Green gradient
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.eco,
                      size: 30,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Welcome to Fresh Market!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF4CAF50)),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.local_grocery_store, color: Color(0xFF4CAF50)),
              title: const Text('Vegetables'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(
                isGridView ? Icons.view_list : Icons.grid_view,
                color: const Color(0xFF4CAF50),
              ),
              title: Text(isGridView ? 'List View' : 'Grid View'),
              onTap: _toggleView,
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Color(0xFF4CAF50)),
              title: const Text('Refresh Menu'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  isLoading = true;
                });
                _loadMenuItems();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF4CAF50)),
              title: const Text('Order History'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Color(0xFFFF6B35)),
              title: const Text('Favorites'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF4CAF50)),
              title: const Text('Profile'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(color: Color(0xFFE8F5E8)),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF757575)),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Color(0xFF757575)),
              title: const Text('Help & Support'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF757575)),
              title: const Text('Logout'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E8)], // Light green gradient
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                )
              : menuItems.isEmpty
              ? const Center(
                  child: Text(
                    'No vegetables available',
                    style: TextStyle(fontSize: 18, color: Color(0xFF757575)),
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
      ),
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE8F5E8), Color(0xFFC8E6C9)], // Light green gradient
                  ),
                ),
                child: const Icon(
                  Icons.eco,
                  size: 60,
                  color: Color(0xFF4CAF50),
                ),
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
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32), // Dark green
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.uom.isNotEmpty)
                    Text(
                      'UOM: ${item.uom}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
                    ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF388E3C), // Medium green
                        ),
                      ),
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isAdded ? const Color(0xFF4CAF50) : const Color(0xFF66BB6A),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (isAdded ? const Color(0xFF4CAF50) : const Color(0xFF66BB6A)).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isAdded ? Icons.check : Icons.add,
                            color: Colors.white,
                            size: 20,
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
                ),
              ),
              child: const Icon(
                Icons.eco,
                size: 30,
                color: Color(0xFF4CAF50),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.uom.isNotEmpty)
                    Text(
                      'UOM: ${item.uom}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF388E3C),
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
                  color: isAdded ? const Color(0xFF4CAF50) : const Color(0xFF66BB6A),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: (isAdded ? const Color(0xFF4CAF50) : const Color(0xFF66BB6A)).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isAdded ? Icons.check : Icons.add,
                  color: Colors.white,
                  size: 24,
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