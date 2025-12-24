import 'package:flutter/material.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';

/// 统一的任务类别定义
class TodoCategories {
  static const List<String> allCategories = [
    'work',
    'study',
    'personal',
    'health',
    'finance',
    'shopping',
    'family',
    'social',
    'hobby',
    'travel',
    'fitness',
    'other',
  ];

  static const Map<String, IconData> categoryIcons = {
    'work': Icons.work,
    'study': Icons.school,
    'personal': Icons.person,
    'health': Icons.favorite,
    'finance': Icons.payments,
    'shopping': Icons.shopping_cart,
    'family': Icons.family_restroom,
    'social': Icons.groups,
    'hobby': Icons.interests,
    'travel': Icons.flight,
    'fitness': Icons.fitness_center,
    'other': Icons.more_horiz,
  };

  static const Map<String, Color> categoryColors = {
    'work': Color(0xFF4A90E2),
    'study': Color(0xFF9C27B0),
    'personal': Color(0xFF4CAF50),
    'health': Color(0xFFE91E63),
    'finance': Color(0xFFFF9800),
    'shopping': Color(0xFF795548),
    'family': Color(0xFF607D8B),
    'social': Color(0xFF00BCD4),
    'hobby': Color(0xFFFF5722),
    'travel': Color(0xFF3F51B5),
    'fitness': Color(0xFF009688),
    'other': Color(0xFF9E9E9E),
  };

  static const Map<String, String> categoryIconNames = {
    'work': 'work',
    'study': 'school',
    'personal': 'person',
    'health': 'favorite',
    'finance': 'payments',
    'shopping': 'shopping_cart',
    'family': 'family_restroom',
    'social': 'groups',
    'hobby': 'interests',
    'travel': 'flight',
    'fitness': 'fitness_center',
    'other': 'more_horiz',
  };

  /// 获取本地化的类别名称
  static String getLocalizedCategory(String category, AppLocalizations l10n) {
    switch (category.toLowerCase()) {
      case 'work':
        return l10n.aiCategoryWork;
      case 'personal':
        return l10n.aiCategoryPersonal;
      case 'study':
        return l10n.aiCategoryStudy;
      case 'health':
        return l10n.aiCategoryHealth;
      case 'fitness':
        return l10n.aiCategoryFitness;
      case 'finance':
        return l10n.aiCategoryFinance;
      case 'shopping':
        return l10n.aiCategoryShopping;
      case 'family':
        return l10n.aiCategoryFamily;
      case 'social':
        return l10n.aiCategorySocial;
      case 'hobby':
        return l10n.aiCategoryHobby;
      case 'travel':
        return l10n.aiCategoryTravel;
      case 'other':
        return l10n.aiCategoryOther;
      default:
        return category;
    }
  }
}