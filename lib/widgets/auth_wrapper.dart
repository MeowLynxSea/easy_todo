import 'package:flutter/material.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/providers/app_settings_provider.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onAuthComplete;

  const AuthWrapper({super.key, required this.child, this.onAuthComplete});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 延迟执行以避免在initState期间访问本地化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAuthentication();
      }
    });
  }

  Future<void> _checkAuthentication() async {
    final appSettingsProvider = Provider.of<AppSettingsProvider>(
      context,
      listen: false,
    );

    // 安全地获取本地化字符串，如果不可用则使用默认值
    String authReason = 'Please use fingerprint to access app';
    try {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        authReason = l10n.authenticateToAccessApp;
      }
    } catch (e) {
      // 如果本地化不可用，使用默认英文
      debugPrint('Localization not available in auth wrapper: $e');
    }

    final isAuthenticated = await appSettingsProvider
        .authenticateForAppAccess(reason: authReason);

    if (mounted) {
      setState(() {
        _isAuthenticated = isAuthenticated;
        _isLoading = false;
      });

      // Call authentication complete callback if provided
      if (isAuthenticated && widget.onAuthComplete != null) {
        widget.onAuthComplete!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.fingerprintAuthenticationFailed,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.authenticateToContinue,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _checkAuthentication,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
