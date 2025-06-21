import 'package:flutter/material.dart';

class OrderingScreen extends StatefulWidget {
  const OrderingScreen({Key? key}) : super(key: key);

  @override
  State<OrderingScreen> createState() => _OrderingScreenState();
}

class _OrderingScreenState extends State<OrderingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int cartItemCount = 0;
  bool isGridView = true; // Track current view mode
  Set<String> addedItems = {}; // Track which items have been added

  final List<MenuItem> menuItems = [
  MenuItem(
    name: 'Okra',
    price: 45.00,
    image: 'https://via.placeholder.com/150x150/4CAF50/FFFFFF?text=Okra',
  ),
  MenuItem(
    name: 'Sitaw',
    price: 40.00,
    image: 'https://via.placeholder.com/150x150/81C784/FFFFFF?text=Sitaw',
  ),
  MenuItem(
    name: 'Patola (Bilog)',
    price: 50.00,
    image: 'https://via.placeholder.com/150x150/66BB6A/FFFFFF?text=Patola',
  ),
  MenuItem(
    name: 'Talong',
    price: 35.00,
    image: 'https://via.placeholder.com/150x150/9575CD/FFFFFF?text=Talong',
  ),
  MenuItem(
    name: 'Ampalaya',
    price: 45.00,
    image: 'https://via.placeholder.com/150x150/388E3C/FFFFFF?text=Ampalaya',
  ),
  MenuItem(
    name: 'Kalabasa',
    price: 30.00,
    image: 'https://via.placeholder.com/150x150/FFA726/FFFFFF?text=Kalabasa',
  ),
  MenuItem(
    name: 'Malunggay',
    price: 20.00,
    image: 'https://via.placeholder.com/150x150/66BB6A/FFFFFF?text=Malunggay',
  ),
  MenuItem(
    name: 'Kangkong',
    price: 15.00,
    image: 'https://via.placeholder.com/150x150/4CAF50/FFFFFF?text=Kangkong',
  ),
  MenuItem(
    name: 'Pechay',
    price: 25.00,
    image: 'https://via.placeholder.com/150x150/AED581/FFFFFF?text=Pechay',
  ),
  MenuItem(
    name: 'Upo',
    price: 30.00,
    image: 'https://via.placeholder.com/150x150/81C784/FFFFFF?text=Upo',
  ),
  MenuItem(
    name: 'Sayote',
    price: 28.00,
    image: 'https://via.placeholder.com/150x150/9CCC65/FFFFFF?text=Sayote',
  ),
  MenuItem(
    name: 'Kamote Tops',
    price: 18.00,
    image: 'https://via.placeholder.com/150x150/7CB342/FFFFFF?text=Kamote',
  ),
  MenuItem(
    name: 'Alugbati',
    price: 22.00,
    image: 'https://via.placeholder.com/150x150/66BB6A/FFFFFF?text=Alugbati',
  ),
  MenuItem(
    name: 'Labanos',
    price: 27.00,
    image: 'https://via.placeholder.com/150x150/EF9A9A/FFFFFF?text=Labanos',
  ),
  MenuItem(
    name: 'Gabi',
    price: 33.00,
    image: 'https://via.placeholder.com/150x150/D7CCC8/FFFFFF?text=Gabi',
  ),
  MenuItem(
    name: 'Mustasa',
    price: 20.00,
    image: 'https://via.placeholder.com/150x150/8BC34A/FFFFFF?text=Mustasa',
  ),
  MenuItem(
    name: 'Sigarilyas',
    price: 32.00,
    image: 'https://via.placeholder.com/150x150/689F38/FFFFFF?text=Sigarilyas',
  ),
  MenuItem(
    name: 'Baguio Beans',
    price: 38.00,
    image: 'https://via.placeholder.com/150x150/4CAF50/FFFFFF?text=Beans',
  ),
  MenuItem(
    name: 'Dahon ng Sili',
    price: 18.00,
    image: 'https://via.placeholder.com/150x150/388E3C/FFFFFF?text=Sili+Leaves',
  ),
  MenuItem(
    name: 'Kinchay',
    price: 20.00,
    image: 'https://via.placeholder.com/150x150/66BB6A/FFFFFF?text=Kinchay',
  ),
];

  void _addToCart(MenuItem item) {
    setState(() {
      cartItemCount++;
      addedItems.add(item.name);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
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
          title: const Text('Cart'),
          content: Text('You have $cartItemCount items in your cart'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
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
        title: const Text('Menu'),
        backgroundColor: Colors.deepOrange,
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
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
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
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepOrange,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.deepOrange,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Welcome!',
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
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Menu'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(isGridView ? Icons.view_list : Icons.grid_view),
              title: Text(isGridView ? 'List View' : 'Grid View'),
              onTap: _toggleView,
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Order History'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
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
            colors: [
              Color(0xFFF5F5F5),
              Color(0xFFE8E8E8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isGridView
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
                      isAdded: addedItems.contains(item.name),
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
                      isAdded: addedItems.contains(item.name),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                color: Colors.grey[200],
                child: const Icon(
                  Icons.fastfood,
                  size: 60,
                  color: Colors.grey,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isAdded ? Colors.green : Colors.deepOrange,
                            borderRadius: BorderRadius.circular(20),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepOrange,
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
                  color: isAdded ? Colors.green : Colors.deepOrange,
                  borderRadius: BorderRadius.circular(25),
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
  final String name;
  final double price;
  final String image;

  MenuItem({
    required this.name,
    required this.price,
    required this.image,
  });
}