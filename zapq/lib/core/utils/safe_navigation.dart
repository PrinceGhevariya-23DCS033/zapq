import 'package:flutter/material.dart';

/// Utility class for safe navigation operations
class SafeNavigation {
  /// Safely pop the current route if possible
  static void safePop(BuildContext context) {
    if (Navigator.canPop(context)) {
      try {
        Navigator.pop(context);
      } catch (e) {
        print('Navigation pop error: $e');
      }
    }
  }

  /// Safely push a new route
  static Future<T?> safePush<T extends Object?>(
    BuildContext context,
    Route<T> route,
  ) async {
    try {
      return await Navigator.push(context, route);
    } catch (e) {
      print('Navigation push error: $e');
      return null;
    }
  }

  /// Safely replace the current route
  static Future<T?> safeReplace<T extends Object?, TO extends Object?>(
    BuildContext context,
    Route<T> newRoute, {
    TO? result,
  }) async {
    try {
      return await Navigator.pushReplacement(context, newRoute, result: result);
    } catch (e) {
      print('Navigation replace error: $e');
      return null;
    }
  }

  /// Safely push and remove until
  static Future<T?> safePushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Route<T> newRoute,
    RoutePredicate predicate,
  ) async {
    try {
      return await Navigator.pushAndRemoveUntil(context, newRoute, predicate);
    } catch (e) {
      print('Navigation pushAndRemoveUntil error: $e');
      return null;
    }
  }

  /// Check if we can safely pop
  static bool canSafePop(BuildContext context) {
    try {
      return Navigator.canPop(context);
    } catch (e) {
      print('Navigation canPop error: $e');
      return false;
    }
  }
}
