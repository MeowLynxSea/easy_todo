import 'package:easy_todo/models/user_preferences_model.dart';
import 'package:easy_todo/providers/theme_provider.dart';
import 'package:easy_todo/services/repositories/user_preferences_repository.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUserPreferencesRepository implements UserPreferencesRepository {
  UserPreferencesModel _model = UserPreferencesModel.create();

  @override
  Future<UserPreferencesModel> load() async => _model;

  @override
  Future<void> save(UserPreferencesModel preferences) async {
    _model = preferences;
  }

  @override
  Future<UserPreferencesModel> update(
    UserPreferencesModel Function(UserPreferencesModel current) transform,
  ) async {
    final next = transform(_model);
    _model = next;
    return _model;
  }
}

void main() {
  test(
    'ThemeProvider does not crash when custom theme misses primary',
    () async {
      final provider = ThemeProvider(
        preferencesRepository: _FakeUserPreferencesRepository(),
      );
      await Future<void>.delayed(Duration.zero);

      provider.setCustomThemeColors(<String, Color>{
        'secondary': const Color(0xFFFF0000),
      });

      final theme = provider.getLightTheme();
      expect(theme.colorScheme.primary, AppTheme.primaryColor);
      expect(theme.colorScheme.secondary, const Color(0xFFFF0000));
    },
  );

  test(
    'ThemeProvider keeps base secondary when custom theme only sets primary',
    () async {
      final provider = ThemeProvider(
        preferencesRepository: _FakeUserPreferencesRepository(),
      );
      await Future<void>.delayed(Duration.zero);

      provider.setCustomThemeColors(<String, Color>{
        'primary': const Color(0xFF00FF00),
      });

      final theme = provider.getLightTheme();
      expect(theme.colorScheme.primary, const Color(0xFF00FF00));
      expect(theme.colorScheme.secondary, AppTheme.secondaryColor);
    },
  );
}
