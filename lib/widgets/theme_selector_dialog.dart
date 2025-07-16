import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
import '../theme/color_themes.dart';

class ThemeSelectorDialog extends StatelessWidget {
  final AppColorPalette currentTheme;
  final int selectedThemeIndex;
  final Function(int) onThemeSelected;

  const ThemeSelectorDialog({
    Key? key,
    required this.currentTheme,
    required this.selectedThemeIndex,
    required this.onThemeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: currentTheme.surface,
      title: Text(
        'Choose Theme',
        style: TextStyle(
          color: currentTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: ColorThemes.allThemes.length,
          itemBuilder: (context, index) {
            final theme = ColorThemes.allThemes[index];
            final themeName = ColorThemes.themeNames[index];
            final isSelected = selectedThemeIndex == index;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? currentTheme.primary : currentTheme.border,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  themeName,
                  style: TextStyle(
                    color: currentTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ],
                ),
                trailing: isSelected 
                    ? Icon(
                        Icons.check_circle,
                        color: currentTheme.primary,
                        size: 24,
                      )
                    : Icon(
                        Icons.circle_outlined,
                        color: currentTheme.textTertiary,
                        size: 24,
                      ),
                onTap: () {
                  onThemeSelected(index);
                  Navigator.pop(context);
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: currentTheme.textTertiary,
          ),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}