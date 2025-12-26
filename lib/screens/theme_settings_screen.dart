import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/web_desktop_content.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  // Predefined theme colors
  static const List<Map<String, dynamic>> themeColors = [
    {
      'primary': Color(0xFF6366F1),
      'primaryVariant': Color(0xFF4F46E5),
      'secondary': Color(0xFF10B981),
      'nameKey': 'themeColorMysteriousPurple',
    },
    {
      'primary': Color(0xFF3B82F6),
      'primaryVariant': Color(0xFF2563EB),
      'secondary': Color(0xFF8B5CF6),
      'nameKey': 'themeColorSkyBlue',
    },
    {
      'primary': Color(0xFF10B981),
      'primaryVariant': Color(0xFF059669),
      'secondary': Color(0xFF3B82F6),
      'nameKey': 'themeColorGemGreen',
    },
    {
      'primary': Color(0xFFF59E0B),
      'primaryVariant': Color(0xFFD97706),
      'secondary': Color(0xFFEF4444),
      'nameKey': 'themeColorLemonYellow',
    },
    {
      'primary': Color(0xFFEF4444),
      'primaryVariant': Color(0xFFDC2626),
      'secondary': Color(0xFFF59E0B),
      'nameKey': 'themeColorFlameRed',
    },
    {
      'primary': Color(0xFF8B5CF6),
      'primaryVariant': Color(0xFF7C3AED),
      'secondary': Color(0xFFEC4899),
      'nameKey': 'themeColorElegantPurple',
    },
    {
      'primary': Color(0xFFEC4899),
      'primaryVariant': Color(0xFFDB2777),
      'secondary': Color(0xFF8B5CF6),
      'nameKey': 'themeColorCherryPink',
    },
    {
      'primary': Color(0xFF14B8A6),
      'primaryVariant': Color(0xFF0D9488),
      'secondary': Color(0xFF6366F1),
      'nameKey': 'themeColorForestCyan',
    },
  ];

  Color? customPrimaryColor;
  Color? customSecondaryColor;

  @override
  void initState() {
    super.initState();
    // Load custom colors from preferences if they exist
    _loadCustomColors();
  }

  Future<void> _loadCustomColors() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    if (themeProvider.customThemeColors != null) {
      customPrimaryColor = themeProvider.customThemeColors!['primary'];
      customSecondaryColor = themeProvider.customThemeColors!['secondary'];
    }
  }

  Color _getVariantColor(Color primaryColor) {
    final hslColor = HSLColor.fromColor(primaryColor);
    return hslColor.withLightness(hslColor.lightness * 0.8).toColor();
  }

  Future<void> _showColorPicker(
    Color initialColor,
    Function(Color) onColorSelected,
  ) async {
    Color selectedColor = initialColor;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectColor),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color preview
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(height: 20),
                // Color slider for hue
                Text(AppLocalizations.of(context)!.hue),
                Slider(
                  value: _getHue(selectedColor),
                  min: 0,
                  max: 360,
                  onChanged: (value) {
                    setState(() {
                      selectedColor = HSLColor.fromAHSL(
                        1,
                        value,
                        0.7,
                        0.5,
                      ).toColor();
                    });
                  },
                ),
                // Color slider for saturation
                Text(AppLocalizations.of(context)!.saturation),
                Slider(
                  value: _getSaturation(selectedColor),
                  min: 0,
                  max: 1,
                  onChanged: (value) {
                    setState(() {
                      selectedColor = HSLColor.fromAHSL(
                        1,
                        _getHue(selectedColor),
                        value,
                        _getLightness(selectedColor),
                      ).toColor();
                    });
                  },
                ),
                // Color slider for lightness
                Text(AppLocalizations.of(context)!.lightness),
                Slider(
                  value: _getLightness(selectedColor),
                  min: 0,
                  max: 1,
                  onChanged: (value) {
                    setState(() {
                      selectedColor = HSLColor.fromAHSL(
                        1,
                        _getHue(selectedColor),
                        _getSaturation(selectedColor),
                        value,
                      ).toColor();
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                onColorSelected(selectedColor);
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      ),
    );
  }

  double _getHue(Color color) {
    return HSLColor.fromColor(color).hue;
  }

  double _getSaturation(Color color) {
    return HSLColor.fromColor(color).saturation;
  }

  double _getLightness(Color color) {
    return HSLColor.fromColor(color).lightness;
  }

  String _getLocalizedThemeName(AppLocalizations l10n, String nameKey) {
    switch (nameKey) {
      case 'themeColorMysteriousPurple':
        return l10n.themeColorMysteriousPurple;
      case 'themeColorSkyBlue':
        return l10n.themeColorSkyBlue;
      case 'themeColorGemGreen':
        return l10n.themeColorGemGreen;
      case 'themeColorLemonYellow':
        return l10n.themeColorLemonYellow;
      case 'themeColorFlameRed':
        return l10n.themeColorFlameRed;
      case 'themeColorElegantPurple':
        return l10n.themeColorElegantPurple;
      case 'themeColorCherryPink':
        return l10n.themeColorCherryPink;
      case 'themeColorForestCyan':
        return l10n.themeColorForestCyan;
      default:
        return nameKey;
    }
  }

  Widget _buildThemeModeSection(ThemeProvider themeProvider) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.themeMode, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        RadioListTile<ThemeMode>(
          title: Row(
            children: [
              Icon(Icons.light_mode_outlined),
              const SizedBox(width: 12),
              Text(l10n.light),
            ],
          ),
          value: ThemeMode.light,
          groupValue: themeProvider.themeMode,
          onChanged: (value) => themeProvider.setThemeMode(value!),
        ),
        RadioListTile<ThemeMode>(
          title: Row(
            children: [
              Icon(Icons.dark_mode_outlined),
              const SizedBox(width: 12),
              Text(l10n.dark),
            ],
          ),
          value: ThemeMode.dark,
          groupValue: themeProvider.themeMode,
          onChanged: (value) => themeProvider.setThemeMode(value!),
        ),
        RadioListTile<ThemeMode>(
          title: Row(
            children: [
              Icon(Icons.settings_suggest_outlined),
              const SizedBox(width: 12),
              Text(l10n.system),
            ],
          ),
          value: ThemeMode.system,
          groupValue: themeProvider.themeMode,
          onChanged: (value) => themeProvider.setThemeMode(value!),
        ),
      ],
    );
  }

  Widget _buildThemeColorsSection(ThemeProvider themeProvider) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.themeColors, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: themeColors.length,
          itemBuilder: (context, index) {
            final themeColor = themeColors[index];
            final isSelected =
                themeProvider.customThemeColors == null &&
                themeProvider.themeColors['primary'] == themeColor['primary'] &&
                themeProvider.themeColors['secondary'] ==
                    themeColor['secondary'];

            return GestureDetector(
              onTap: () {
                // Apply theme colors
                final colors = <String, Color>{
                  'primary': themeColor['primary'],
                  'primaryVariant': themeColor['primaryVariant'],
                  'secondary': themeColor['secondary'],
                };
                themeProvider.setThemeColors(colors);
                themeProvider.clearCustomTheme(); // Clear custom theme

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${l10n.themeColorApplied}: ${_getLocalizedThemeName(l10n, themeColor['nameKey'])}',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeColor['primary'],
                            themeColor['primaryVariant'],
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? themeColor['primary']
                              : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getLocalizedThemeName(l10n, themeColor['nameKey']),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected ? themeColor['primary'] : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomThemeSection(ThemeProvider themeProvider) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.customTheme, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Primary color picker
                ListTile(
                  title: Text(l10n.primaryColor),
                  subtitle: Text(l10n.selectPrimaryColor),
                  trailing: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          customPrimaryColor ??
                          themeProvider.themeColors['primary'],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  onTap: () {
                    _showColorPicker(
                      customPrimaryColor ??
                          themeProvider.themeColors['primary']!,
                      (color) => setState(() => customPrimaryColor = color),
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Secondary color picker
                ListTile(
                  title: Text(l10n.secondaryColor),
                  subtitle: Text(l10n.selectSecondaryColor),
                  trailing: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          customSecondaryColor ??
                          themeProvider.themeColors['secondary'],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  onTap: () {
                    _showColorPicker(
                      customSecondaryColor ??
                          themeProvider.themeColors['secondary']!,
                      (color) => setState(() => customSecondaryColor = color),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Apply and Reset buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (customPrimaryColor != null ||
                              customSecondaryColor != null) {
                            // Apply custom theme
                            final customColors = <String, Color>{};
                            if (customPrimaryColor != null) {
                              customColors['primary'] = customPrimaryColor!;
                              customColors['primaryVariant'] = _getVariantColor(
                                customPrimaryColor!,
                              );
                            }
                            if (customSecondaryColor != null) {
                              customColors['secondary'] = customSecondaryColor!;
                            }
                            themeProvider.setCustomThemeColors(customColors);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.customThemeApplied),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Text(l10n.applyCustomTheme),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            customPrimaryColor = null;
                            customSecondaryColor = null;
                          });
                          themeProvider.resetToDefaultTheme();
                        },
                        child: Text(AppLocalizations.of(context)!.resetButton),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.themeSettings)),
      body: WebDesktopContent(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThemeModeSection(themeProvider),
              const SizedBox(height: 32),
              _buildThemeColorsSection(themeProvider),
              const SizedBox(height: 32),
              _buildCustomThemeSection(themeProvider),
            ],
          ),
        ),
      ),
    );
  }
}
