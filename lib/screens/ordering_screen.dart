import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../theme/app_color_palette.dart';
import '../services/theme_manager.dart';
import '../services/menu_service.dart';
import '../widgets/menu_item_tile.dart';
import '../widgets/menu_item_list_tile.dart';
import '../widgets/theme_selector_dialog.dart';
import '../widgets/cart_dialog.dart';
import '../widgets/custom_drawer.dart';

class OrderingScreen extends StatefulWidget {
  const OrderingScreen({Key? key}) : super(key: key);

  @override
  State<OrderingScreen> createState() => _OrderingScreenState();
}

class _OrderingScreenState extends State<OrderingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MenuService _menuService = MenuService();

  int cartItemCount = 0;
  bool isGridView = true;
  Set<String> addedItems = {};
  List<MenuItem> menuItems = [];
  bool isLoading = true;
  bool isDarkMode = false;
  AppColorPalette currentTheme = ThemeManager.applyTheme(0, false);
  int selectedThemeIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadMenuItems();
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

  void _addToCart(MenuItem item) {
    setState(() {
      cartItemCount++;
      addedItems.add(item.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
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
            currentTheme = ThemeManager.applyTheme(selectedThemeIndex, isDarkMode);
          });
          _savePreferences();
        },
      ),
    );
  }

  void _viewCart() {
    showDialog(
      context: context,
      builder: (BuildContext context) => CartDialog(
        theme: currentTheme,
        cartItemCount: cartItemCount,
      ),
    );
  }

  void _refreshMenu() {
    setState(() {
      isLoading = true;
    });
    _loadMenuItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: currentTheme.background,
      appBar: AppBar(
        title: Text(
          'Menu',
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
                      color: currentTheme.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartItemCount',
                      style: TextStyle(
                        color: currentTheme.surface,
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
      drawer: CustomDrawer(
        theme: currentTheme,
        isGridView: isGridView,
        isDarkMode: isDarkMode,
        onToggleView: _toggleView,
        onToggleDarkMode: _toggleDarkMode,
        onThemeSelector: _showThemeSelector,
        onRefreshMenu: _refreshMenu,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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
        return MenuItemTile(
          item: item,
          onAddToCart: () => _addToCart(item),
          isAdded: addedItems.contains(item.id),
          theme: currentTheme,
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return MenuItemListTile(
          item: item,
          onAddToCart: () => _addToCart(item),
          isAdded: addedItems.contains(item.id),
          theme: currentTheme,
        );
      },
    );
  }
}