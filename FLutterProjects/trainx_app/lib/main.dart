import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'config/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool loggedIn = await AuthService.isLoggedIn();
  runApp(TrainXStudentApp(isLoggedIn: loggedIn));
}

class TrainXStudentApp extends StatelessWidget {
  final bool isLoggedIn;
  const TrainXStudentApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrainX Student',
      debugShowCheckedModeBanner: false,
      theme: TrainXTheme.theme,
      scrollBehavior: const NoStretchScrollBehavior(),
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}

// Globally disables Android 12+ elastic stretch/rubber-band overscroll across all screens
class NoStretchScrollBehavior extends ScrollBehavior {
  const NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child; // Removes the stretch animation entirely
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics(); // Firm clamping scroll with zero bounce/stretch
  }
}

typedef MyApp = TrainXStudentApp;
