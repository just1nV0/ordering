import 'package:flutter/material.dart';
import '../api_helpers/sqlite/insert_sqlite.dart';
import '../api_helpers/sqlite/read_sqlite.dart';

// Color Palette System
class AppColorPalette {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color success;
  final Color error;
  final Color warning;

  const AppColorPalette({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.success,
    required this.error,
    required this.warning,
  });
}

class ColorThemes {
  // 1. Fresh Green Theme (Vegetable-themed)
  static const AppColorPalette freshGreen = AppColorPalette(
    primary: Color(0xFF4CAF50),
    primaryLight: Color(0xFF66BB6A),
    primaryDark: Color(0xFF2E7D32),
    secondary: Color(0xFF81C784),
    accent: Color(0xFFFF6B35),
    background: Color(0xFFF1F8E9),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE8F5E8),
    textPrimary: Color(0xFF2E7D32),
    textSecondary: Color(0xFF424242),
    textTertiary: Color(0xFF757575),
    border: Color(0xFFE8F5E8),
    success: Color(0xFF4CAF50),
    error: Color(0xFFE57373),
    warning: Color(0xFFFF6B35),
  );

  // 2. Minimalist Theme
  static const AppColorPalette minimalist = AppColorPalette(
    primary: Color(0xFF212121),
    primaryLight: Color(0xFF424242),
    primaryDark: Color(0xFF000000),
    secondary: Color(0xFF757575),
    accent: Color(0xFF9E9E9E),
    background: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF5F5F5),
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF424242),
    textTertiary: Color(0xFF9E9E9E),
    border: Color(0xFFE0E0E0),
    success: Color(0xFF212121),
    error: Color(0xFF424242),
    warning: Color(0xFF757575),
  );

  // 3. Modern Blue Theme
  static const AppColorPalette modernBlue = AppColorPalette(
    primary: Color(0xFF2196F3),
    primaryLight: Color(0xFF42A5F5),
    primaryDark: Color(0xFF1565C0),
    secondary: Color(0xFF64B5F6),
    accent: Color(0xFFFF4081),
    background: Color(0xFFF3F8FF),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE3F2FD),
    textPrimary: Color(0xFF1565C0),
    textSecondary: Color(0xFF424242),
    textTertiary: Color(0xFF757575),
    border: Color(0xFFE3F2FD),
    success: Color(0xFF4CAF50),
    error: Color(0xFFE57373),
    warning: Color(0xFFFF9800),
  );

  // 4. Modern Purple Theme
  static const AppColorPalette modernPurple = AppColorPalette(
    primary: Color(0xFF9C27B0),
    primaryLight: Color(0xFFBA68C8),
    primaryDark: Color(0xFF6A1B9A),
    secondary: Color(0xFFCE93D8),
    accent: Color(0xFF00BCD4),
    background: Color(0xFFFAF4FF),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF3E5F5),
    textPrimary: Color(0xFF6A1B9A),
    textSecondary: Color(0xFF424242),
    textTertiary: Color(0xFF757575),
    border: Color(0xFFF3E5F5),
    success: Color(0xFF4CAF50),
    error: Color(0xFFE57373),
    warning: Color(0xFFFF9800),
  );

  // 5. Pastel Green Theme
  static const AppColorPalette pastelGreen = AppColorPalette(
    primary: Color(0xFF8BC34A),
    primaryLight: Color(0xFFAED581),
    primaryDark: Color(0xFF689F38),
    secondary: Color(0xFFC8E6C9),
    accent: Color(0xFFFFB74D),
    background: Color(0xFFF9FBF7),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F8E9),
    textPrimary: Color(0xFF689F38),
    textSecondary: Color(0xFF5D4037),
    textTertiary: Color(0xFF8D6E63),
    border: Color(0xFFE8F5E8),
    success: Color(0xFF8BC34A),
    error: Color(0xFFEF9A9A),
    warning: Color(0xFFFFCC02),
  );

  // 6. Pastel Blue Theme
  static const AppColorPalette pastelBlue = AppColorPalette(
    primary: Color(0xFF81D4FA),
    primaryLight: Color(0xFFB3E5FC),
    primaryDark: Color(0xFF0277BD),
    secondary: Color(0xFFB0BEC5),
    accent: Color(0xFFFFAB91),
    background: Color(0xFFF7FCFF),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE1F5FE),
    textPrimary: Color(0xFF0277BD),
    textSecondary: Color(0xFF37474F),
    textTertiary: Color(0xFF78909C),
    border: Color(0xFFE1F5FE),
    success: Color(0xFF4CAF50),
    error: Color(0xFFEF9A9A),
    warning: Color(0xFFFFCC02),
  );

  // 7. Modern Orange Theme
  static const AppColorPalette modernOrange = AppColorPalette(
    primary: Color(0xFFFF5722),
    primaryLight: Color(0xFFFF7043),
    primaryDark: Color(0xFFD84315),
    secondary: Color(0xFFFF8A65),
    accent: Color(0xFF03DAC6),
    background: Color(0xFFFFF8F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFFBE9E7),
    textPrimary: Color(0xFFD84315),
    textSecondary: Color(0xFF424242),
    textTertiary: Color(0xFF757575),
    border: Color(0xFFFBE9E7),
    success: Color(0xFF4CAF50),
    error: Color(0xFFE57373),
    warning: Color(0xFFFF9800),
  );

  // 8. Pastel Pink Theme
  static const AppColorPalette pastelPink = AppColorPalette(
    primary: Color(0xFFF8BBD9),
    primaryLight: Color(0xFFFCE4EC),
    primaryDark: Color(0xFFAD1457),
    secondary: Color(0xFFF48FB1),
    accent: Color(0xFF80CBC4),
    background: Color(0xFFFFFAFD),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFFCE4EC),
    textPrimary: Color(0xFFAD1457),
    textSecondary: Color(0xFF4A148C),
    textTertiary: Color(0xFF7B1FA2),
    border: Color(0xFFFCE4EC),
    success: Color(0xFF81C784),
    error: Color(0xFFEF9A9A),
    warning: Color(0xFFFFCC02),
  );

  // Dark Mode Themes
  // 9. Dark Green Theme
  static const AppColorPalette darkGreen = AppColorPalette(
    primary: Color(0xFF66BB6A),
    primaryLight: Color(0xFF81C784),
    primaryDark: Color(0xFF388E3C),
    secondary: Color(0xFF4CAF50),
    accent: Color(0xFFFF6B35),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceVariant: Color(0xFF2C2C2C),
    textPrimary: Color(0xFFE8F5E8),
    textSecondary: Color(0xFFB8B8B8),
    textTertiary: Color(0xFF888888),
    border: Color(0xFF3A3A3A),
    success: Color(0xFF66BB6A),
    error: Color(0xFFCF6679),
    warning: Color(0xFFFF6B35),
  );

  // 10. Dark Minimalist Theme
  static const AppColorPalette darkMinimalist = AppColorPalette(
    primary: Color(0xFFFFFFFF),
    primaryLight: Color(0xFFE0E0E0),
    primaryDark: Color(0xFFBDBDBD),
    secondary: Color(0xFF9E9E9E),
    accent: Color(0xFF757575),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceVariant: Color(0xFF2C2C2C),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFE0E0E0),
    textTertiary: Color(0xFF9E9E9E),
    border: Color(0xFF3A3A3A),
    success: Color(0xFFFFFFFF),
    error: Color(0xFFCF6679),
    warning: Color(0xFF9E9E9E),
  );

  static List<AppColorPalette> get allThemes => [
    freshGreen,      // 1
    minimalist,      // 2
    modernBlue,      // 3
    modernPurple,    // 4
    pastelGreen,     // 5
    pastelBlue,      // 6
    modernOrange,    // 7
    pastelPink,      // 8
    darkGreen,       // 9
    darkMinimalist,  // 10
  ];

  static List<String> get themeNames => [
    'Fresh Green',
    'Minimalist',
    'Modern Blue',
    'Modern Purple',
    'Pastel Green',
    'Pastel Blue',
    'Modern Orange',
    'Pastel Pink',
    'Dark Green',
    'Dark Minimalist',
  ];
}

class OrderingScreen extends StatefulWidget {
  const OrderingScreen({Key? key}) : super(key: key);

  @override
  State<OrderingScreen> createState() => _OrderingScreenState();
}

class _OrderingScreenState extends State<OrderingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DBReader _dbReader = DBReader();

  int cartItemCount = 0;
  bool isGridView = true;
  Set<String> addedItems = {};
  List<MenuItem> menuItems = [];
  bool isLoading = true;
  
  // Theme management
  int selectedThemeIndex = 0; // Default to Fresh Green theme
  bool isDarkMode = false;

  AppColorPalette get currentTheme {
    if (isDarkMode) {
      // Return dark themes (index 8 and 9)
      return selectedThemeIndex == 1 
          ? ColorThemes.darkMinimalist 
          : ColorThemes.darkGreen;
    }
    return ColorThemes.allThemes[selectedThemeIndex];
  }

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

      setState(() {
        menuItems = items
            .map(
              (item) => MenuItem(
                id: item['ctr']?.toString() ?? '',
                name: item['itemname']?.toString() ?? 'Unknown Item',
                price: 0.00,
                uom: item['uom']?.toString() ?? '',
                image: '',
              ),
            )
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading menu items: $e'),
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
    Navigator.pop(context);
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _changeTheme(int themeIndex) {
    setState(() {
      selectedThemeIndex = themeIndex;
    });
    Navigator.pop(context);
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: currentTheme.surface,
          title: Text(
            'Choose Theme',
            style: TextStyle(
              color: currentTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: isDarkMode ? 2 : ColorThemes.themeNames.length - 2, // Exclude dark themes in light mode
              itemBuilder: (context, index) {
                final actualIndex = isDarkMode ? index + 8 : index; // Offset for dark themes
                final themeName = isDarkMode 
                    ? ColorThemes.themeNames[actualIndex]
                    : ColorThemes.themeNames[index];
                final isSelected = isDarkMode 
                    ? (index == (selectedThemeIndex == 1 ? 1 : 0))
                    : (index == selectedThemeIndex);
                
                return ListTile(
                  title: Text(
                    themeName,
                    style: TextStyle(color: currentTheme.textSecondary),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isDarkMode 
                        ? (index == 0 ? ColorThemes.darkGreen.primary : ColorThemes.darkMinimalist.primary)
                        : ColorThemes.allThemes[index].primary,
                    radius: 12,
                  ),
                  trailing: isSelected 
                      ? Icon(Icons.check, color: currentTheme.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _changeTheme(isDarkMode ? actualIndex : index);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _viewCart() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: currentTheme.surface,
          title: Text(
            'Cart',
            style: TextStyle(
              color: currentTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: Text(
            'You have $cartItemCount items in your cart',
            style: TextStyle(color: currentTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: currentTheme.textTertiary,
              ),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: currentTheme.surface,
                backgroundColor: currentTheme.primary,
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
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleDarkMode,
          ),
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
      drawer: Drawer(
        backgroundColor: currentTheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: currentTheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: currentTheme.surface,
                    child: Icon(
                      Icons.person_outline,
                      size: 30,
                      color: currentTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome',
                    style: TextStyle(
                      color: currentTheme.surface,
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
            _buildDrawerItem(Icons.palette_outlined, 'Change Theme', onTap: _showThemeSelector),
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
            Divider(color: currentTheme.border, height: 32),
            _buildDrawerItem(Icons.settings_outlined, 'Settings'),
            _buildDrawerItem(Icons.help_outline, 'Help & Support'),
            _buildDrawerItem(Icons.logout_outlined, 'Logout'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: currentTheme.primary,
                  strokeWidth: 2,
                ),
              )
            : menuItems.isEmpty
            ? Center(
                child: Text(
                  'No items available',
                  style: TextStyle(
                    fontSize: 16,
                    color: currentTheme.textTertiary,
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
                    theme: currentTheme,
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
                    theme: currentTheme,
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
        color: currentTheme.textTertiary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: currentTheme.textSecondary,
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
  final AppColorPalette theme;

  const MenuItemTile({
    Key? key,
    required this.item,
    required this.onAddToCart,
    required this.isAdded,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

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
    return Container(
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
              onTap: onAddToCart,
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