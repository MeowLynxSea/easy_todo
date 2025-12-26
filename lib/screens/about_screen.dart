import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_todo/widgets/web_desktop_content.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutEasyTodo), centerTitle: true),
      body: WebDesktopContent(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // App Icon and Basic Info
              _buildAppInfoSection(l10n),
              const SizedBox(height: 24),

              // Description
              _buildDescriptionSection(l10n),
              const SizedBox(height: 24),

              // Developer Information
              _buildDeveloperSection(l10n),
              const SizedBox(height: 24),

              // Open Source Licenses
              _buildOpenSourceSection(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoSection(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.task_alt,
                      size: 50,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.easyTodo,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.version} ${_packageInfo?.version ?? l10n.version}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appDescription,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.appLongDescription,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  l10n.developer,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.badge,
              title: l10n.developerName,
              value: '梦凌汐 (MeowLynxSea)',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.email,
              title: l10n.email,
              value: 'mew@meowdream.cn',
              onTap: () => _launchUrl('mailto:mew@meowdream.cn'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenSourceSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  l10n.openSource,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This app is built with love using the following open source libraries:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildLicenseItem(
              'Flutter',
              'Google',
              'https://flutter.dev',
              'BSD 3-Clause',
            ),
            _buildLicenseItem(
              'Dart',
              'Google',
              'https://dart.dev',
              'BSD 3-Clause',
            ),
            _buildLicenseItem(
              'Provider',
              'Flutter Community',
              'https://pub.dev/packages/provider',
              'MIT',
            ),
            _buildLicenseItem(
              'Hive',
              'Simon Leier',
              'https://pub.dev/packages/hive',
              'Apache 2.0',
            ),
            _buildLicenseItem(
              'FL Chart',
              'FL Community',
              'https://pub.dev/packages/fl_chart',
              'Apache 2.0',
            ),
            _buildLicenseItem(
              'Material Design Icons',
              'Google',
              'https://material.io/icons',
              'Apache 2.0',
            ),
            _buildLicenseItem(
              'Cupertino Icons',
              'Flutter Community',
              'https://pub.dev/packages/cupertino_icons',
              'MIT',
            ),
            _buildLicenseItem(
              'Table Calendar',
              'Aleksandar Mitev',
              'https://pub.dev/packages/table_calendar',
              'Apache 2.0',
            ),
            _buildLicenseItem(
              'URL Launcher',
              'Flutter Community',
              'https://pub.dev/packages/url_launcher',
              'BSD 3-Clause',
            ),
            _buildLicenseItem(
              'Package Info Plus',
              'Flutter Community',
              'https://pub.dev/packages/package_info_plus',
              'BSD 3-Clause',
            ),
            _buildLicenseItem(
              'File Picker',
              'Miguel Ruivo',
              'https://pub.dev/packages/file_picker',
              'MIT',
            ),
            _buildLicenseItem(
              'Flutter Intl',
              'Localizely',
              'https://pub.dev/packages/flutter_intl',
              'BSD 3-Clause',
            ),
            _buildLicenseItem(
              'Flutter Staggered Animations',
              'Gianluca Berti',
              'https://pub.dev/packages/flutter_staggered_animations',
              'MIT',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseItem(
    String name,
    String author,
    String url,
    String license,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    license,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'by $author',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Copy to clipboard
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.copiedToClipboard(url)),
              action: SnackBarAction(
                label: l10n.ok,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Fallback: Copy to clipboard on error
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cannotOpenLink(url)),
            action: SnackBarAction(
              label: l10n.ok,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }
}
