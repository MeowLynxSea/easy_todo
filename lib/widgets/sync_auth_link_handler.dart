import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/providers/sync_provider.dart';
import 'package:easy_todo/screens/sync_settings_screen.dart';
import 'package:easy_todo/utils/responsive.dart';
import 'package:easy_todo/services/web_url_utils_stub.dart'
    if (dart.library.html) 'package:easy_todo/services/web_url_utils_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SyncAuthLinkHandler extends StatefulWidget {
  final Widget child;

  const SyncAuthLinkHandler({super.key, required this.child});

  @override
  State<SyncAuthLinkHandler> createState() => _SyncAuthLinkHandlerState();
}

class _SyncAuthLinkHandlerState extends State<SyncAuthLinkHandler> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  String? _lastHandledTicket;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (kIsWeb) {
        unawaited(_handleWebInitialUrl());
      } else {
        unawaited(_initAppLinks());
      }
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  Future<void> _initAppLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handleUri(initial);
      }
    } catch (_) {}

    _sub = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handleUri(uri)),
      onError: (_) {},
    );
  }

  Future<void> _handleWebInitialUrl() async {
    final uri = currentWebUrl();
    await _handleUri(uri);
  }

  String? _extractTicket(Uri uri) {
    return (uri.queryParameters['ticket'] ?? uri.queryParameters['amp;ticket'])
        ?.trim();
  }

  bool _isWebTicketCallback(Uri uri) {
    if (!kIsWeb) return false;
    final ticket = _extractTicket(uri);
    return ticket != null && ticket.isNotEmpty;
  }

  void _cleanupWebTicketFromUrl() {
    if (!kIsWeb) return;
    final current = currentWebUrl();
    final qp = Map<String, String>.from(current.queryParameters);
    qp.remove('ticket');
    qp.remove('amp;ticket');
    replaceWebUrl(current.replace(queryParameters: qp));
  }

  bool _isSyncAuthUri(Uri uri) {
    if (uri.scheme != 'easy_todo') return false;
    if (uri.host == 'auth') return true;
    if (uri.host.isEmpty && uri.path == 'auth') return true;
    return false;
  }

  Future<void> _handleUri(Uri uri) async {
    if (!mounted) return;
    final shouldHandle = _isSyncAuthUri(uri) || _isWebTicketCallback(uri);
    if (!shouldHandle) return;

    final ticket = _extractTicket(uri);
    if (ticket == null || ticket.isEmpty) return;
    if (_lastHandledTicket == ticket) return;
    _lastHandledTicket = ticket;

    if (kIsWeb) {
      _cleanupWebTicketFromUrl();
    }

    final l10n = AppLocalizations.of(context)!;
    final sync = context.read<SyncProvider>();

    final dialogFuture = showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(l10n.cloudSyncAuthProcessingTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  l10n.cloudSyncAuthProcessingSubtitle,
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      await sync.exchangeAuthTicket(ticket);
    } catch (_) {
      // Errors are surfaced via SyncProvider UI state.
    } finally {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      await dialogFuture.catchError((_) {});
    }

    if (!mounted) return;
    if (isWebDesktop(context)) {
      const inset = 24.0;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final size = MediaQuery.sizeOf(dialogContext);
          final width = (size.width - inset * 2).clamp(360.0, 720.0);
          final height = (size.height - inset * 2).clamp(480.0, 860.0);

          return Dialog(
            insetPadding: const EdgeInsets.all(inset),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: width,
              height: height,
              child: const SyncSettingsScreen(),
            ),
          );
        },
      );
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SyncSettingsScreen()));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
