import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/update_model.dart';
import 'package:easy_todo/services/update_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ForcedUpdatePage extends StatelessWidget {
  final UpdateInfo updateInfo;
  final UpdateService updateService;

  const ForcedUpdatePage({
    super.key,
    required this.updateInfo,
    required this.updateService,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.updateAvailable)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.updateAvailable,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(updateInfo.message),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final url = updateInfo.downloadUrl;
                if (url == null || url.isEmpty) return;
                final uri = Uri.tryParse(url);
                if (uri == null) return;
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Text(l10n.updateNow),
            ),
            const SizedBox(height: 12),
            Text(
              'Web does not support in-app updates.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
