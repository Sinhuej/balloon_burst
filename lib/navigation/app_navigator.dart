import 'package:flutter/widgets.dart';
import '../routes.dart';

class AppNavigator {
  const AppNavigator._();

  static void goToGame(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.game);
  }
}
