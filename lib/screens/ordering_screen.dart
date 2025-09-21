import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';
import '../screens/order_history_screen.dart';
import '../theme/app_color_palette.dart';
import '../services/theme_manager.dart';
import '../services/menu_service.dart';
import '../widgets/menu_item_tile.dart';
import '../widgets/menu_item_list_tile.dart';
import '../widgets/theme_selector_dialog.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/cart_widget.dart';

class OrderingScreen extends StatefulWidget {
  const OrderingScreen({Key? key}) : super(key: key);

  @override
  State<OrderingScreen> createState() => _OrderingScreenState();
}

class _OrderingScreenState extends State<OrderingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MenuService _menuService = MenuService();
  final PageController _pageController = PageController();

  List<CartItem> cartItems = [];
  int get cartItemCount =>
      cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
  bool isGridView = true;
  Set<String> addedItems = {};
  List<MenuItem> menuItems = [];
  bool isLoading = true;
  bool isDarkMode = false;
  AppColorPalette currentTheme = ThemeManager.applyTheme(0, false);
  int selectedThemeIndex = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadMenuItems();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final preferences = await ThemeManager.loadPreferences();

    setState(() {
      selectedThemeIndex = preferences['selectedThemeIndex'];
      isDarkMode = preferences['isDarkMode'];
      isGridView = preferences['isGridView'];
      currentTheme = ThemeManager.applyTheme(selectedThemeIndex, isDarkMode);
    });
  }

  Future<void> _savePreferences() async {
    await ThemeManager.savePreferences(
      selectedThemeIndex: selectedThemeIndex,
      isDarkMode: isDarkMode,
      isGridView: isGridView,
    );
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
      currentTheme = ThemeManager.applyTheme(selectedThemeIndex, isDarkMode);
    });
    _savePreferences();
  }

  Future<void> _loadMenuItems() async {
    try {
      final items = await _menuService.loadMenuItems();
      setState(() {
        menuItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: currentTheme.error,
          ),
        );
      }
    }
  }

  void _addToCart(MenuItem item, [int quantity = 1]) {
    setState(() {
      final existingItemIndex = cartItems.indexWhere(
        (cartItem) => cartItem.menuItem.id == item.id,
      );
      if (existingItemIndex != -1) {
        cartItems[existingItemIndex].quantity = quantity;
      } else {
        cartItems.add(CartItem(menuItem: item, quantity: quantity));
      }

      addedItems.add(item.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$quantity ${item.name}${quantity > 1 ? 's' : ''} added to cart',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: currentTheme.success,
      ),
    );
  }

  void _toggleView() {
    setState(() {
      isGridView = !isGridView;
    });
    _savePreferences();
    Navigator.pop(context);
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) => ThemeSelectorDialog(
        currentTheme: currentTheme,
        selectedThemeIndex: selectedThemeIndex,
        onThemeSelected: (index) {
          setState(() {
            selectedThemeIndex = index;
            currentTheme = ThemeManager.applyTheme(
              selectedThemeIndex,
              isDarkMode,
            );
          });
          _savePreferences();
        },
      ),
    );
  }

  void _refreshMenu() {
    setState(() {
      isLoading = true;
    });
    _loadMenuItems();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  int get cartBadgeCount {
    final uniqueCtrs = <String>{};
    for (final c in cartItems) {
      if (c.quantity <= 0) continue;
      final ctr = c.menuItem.id;
      uniqueCtrs.add(ctr.toString());
    }
    return uniqueCtrs.length;
  }

  String _cartCountLabel(int count) => count > 99 ? '99+' : '$count';

  Widget _ordersIcon({required bool active}) {
    final icon = Icon(
      active ? Icons.receipt_long : Icons.receipt_long_outlined,
      color: active ? currentTheme.primary : null,
    );

    return Badge(
      isLabelVisible: cartBadgeCount > 0,
      alignment: Alignment.topRight,
      offset: const Offset(6, -6),
      backgroundColor: currentTheme.accent,
      label: Text(
        _cartCountLabel(cartBadgeCount),
        style: TextStyle(
          color: currentTheme.surface,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: icon,
    );
  }

  List<String> get _appBarTitles => [
    'Home',
    'Orders',
    'Account',
    'Notifications',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: currentTheme.background,
      appBar: AppBar(
        title: Text(
          _appBarTitles[_currentIndex],
          style: TextStyle(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: currentTheme.textPrimary,
          ),
        ),
        backgroundColor: currentTheme.surface,
        foregroundColor: currentTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: _currentIndex == 0
          ? CustomDrawer(
              theme: currentTheme,
              isGridView: isGridView,
              isDarkMode: isDarkMode,
              onToggleView: _toggleView,
              onToggleDarkMode: _toggleDarkMode,
              onThemeSelector: _showThemeSelector,
              onRefreshMenu: _refreshMenu,
            )
          : null,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          Padding(padding: const EdgeInsets.all(16.0), child: _buildMenuBody()),
          _buildOrdersTab(),
          OrderHistoryScreen(theme: currentTheme),
          _buildNotificationsBody(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: currentTheme.surface,
          boxShadow: [
            BoxShadow(
              color: currentTheme.textPrimary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          backgroundColor: currentTheme.surface,
          selectedItemColor: currentTheme.primary,
          unselectedItemColor: currentTheme.textSecondary,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home, color: currentTheme.primary),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _ordersIcon(active: false),
              activeIcon: _ordersIcon(active: true),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_circle_outlined),
              activeIcon: Icon(
                Icons.account_circle,
                color: currentTheme.primary,
              ),
              label: 'Account',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.notifications_outlined),
              activeIcon: Icon(
                Icons.notifications,
                color: currentTheme.primary,
              ),
              label: 'Notifications',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuBody() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: currentTheme.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (menuItems.isEmpty) {
      return Center(
        child: Text(
          'No items available',
          style: TextStyle(
            fontSize: 16,
            color: currentTheme.textTertiary,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    return isGridView ? _buildGridView() : _buildListView();
  }

  Widget _buildGridView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final existingQty = cartItems
            .firstWhere(
              (c) => c.menuItem.id == item.id,
              orElse: () => CartItem(menuItem: item, quantity: 1),
            )
            .quantity;
        return MenuItemTile(
          item: item,
          onAddToCart: () => _addToCart(item),
          isAdded: addedItems.contains(item.id),
          theme: currentTheme,
          currentQuantity: existingQty,
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final existingQty = cartItems
            .firstWhere(
              (c) => c.menuItem.id == item.id,
              orElse: () => CartItem(menuItem: item, quantity: 1),
            )
            .quantity;
        return MenuItemListTile(
          item: item,
          onAddToCart: () => _addToCart(item),
          isAdded: addedItems.contains(item.id),
          currentQuantity: existingQty,
          theme: currentTheme,
        );
      },
    );
  }

  Widget _buildOrdersTab() {
    return CartWidget(
      theme: currentTheme,
      cartItems: cartItems,
      onCartUpdated: (updated) {
        setState(() {
          cartItems.clear();
          cartItems.addAll(updated);
          addedItems.clear();
          for (var c in cartItems) addedItems.add(c.menuItem.id);
        });
      },
      onCheckoutComplete: () {
        setState(() {
          cartItems.clear();
          addedItems.clear();
        });
      },
    );
  }

  Widget _buildNotificationsBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_outlined,
            size: 64,
            color: currentTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: currentTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Important updates and alerts will appear here',
            style: TextStyle(fontSize: 16, color: currentTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
