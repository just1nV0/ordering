import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';

class CustomDrawer extends StatelessWidget {
  final AppColorPalette theme;
  final bool isGridView;
  final bool isDarkMode;
  final VoidCallback onToggleView;
  final VoidCallback onToggleDarkMode;
  final VoidCallback onThemeSelector;
  final VoidCallback onRefreshMenu;

  const CustomDrawer({
    Key? key,
    required this.theme,
    required this.isGridView,
    required this.isDarkMode,
    required this.onToggleView,
    required this.onToggleDarkMode,
    required this.onThemeSelector,
    required this.onRefreshMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: theme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.surface,
                  child: Icon(
                    Icons.person_outline,
                    size: 30,
                    color: theme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome',
                  style: TextStyle(
                    color: theme.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(context, Icons.home_outlined, 'Home'),
          _buildDrawerItem(context, Icons.restaurant_menu_outlined, 'Menu'),
          _buildDrawerItem(
            context,
            isGridView ? Icons.view_list_outlined : Icons.grid_view_outlined,
            isGridView ? 'List View' : 'Grid View',
            onTap: onToggleView,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ListTile(
              leading: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: theme.textTertiary,
                size: 22,
              ),
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              trailing: Icon(
                isDarkMode ? Icons.toggle_on : Icons.toggle_off,
                color: isDarkMode ? theme.primary : theme.textTertiary,
                size: 32,
              ),
              onTap: onToggleDarkMode,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          _buildDrawerItem(
            context,
            Icons.palette_outlined, 
            'Choose Theme', 
            onTap: () {
              Navigator.pop(context);
              onThemeSelector();
            }
          ),
          _buildDrawerItem(
            context, 
            Icons.refresh_outlined, 
            'Refresh Menu', 
            onTap: () {
              Navigator.pop(context);
              onRefreshMenu();
            }
          ),
          _buildDrawerItem(context, Icons.history_outlined, 'Order History'),
          _buildDrawerItem(context, Icons.favorite_outline, 'Favorites'),
          _buildDrawerItem(context, Icons.person_outline, 'Profile'),
          Divider(color: theme.border, height: 32),
          _buildDrawerItem(context, Icons.settings_outlined, 'Settings'),
          _buildDrawerItem(context, Icons.help_outline, 'Help & Support'),
          _buildDrawerItem(context, Icons.logout_outlined, 'Logout'),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        color: theme.textTertiary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: theme.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap ?? () => Navigator.pop(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}