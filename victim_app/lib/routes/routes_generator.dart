import 'package:flutter/material.dart';
import 'package:smart_108/pages/forgot_pass.dart';
import 'package:smart_108/pages/profile.dart';
// import 'package:smart_108/pages/login.dart';
import 'package:smart_108/pages/register.dart';
import 'package:smart_108/pages/requestHistory.dart';
import 'app_routes.dart';




class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {

      // case AppRoutes.login:
      //   return MaterialPageRoute(builder: (_) => const LoginPage());

      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case AppRoutes.forgotPass:
        return MaterialPageRoute(builder: (_) => const ForgotPassPage());

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) =>
          const Scaffold(body: Center(child: Text('Route not found'))),
    );
  }
}
