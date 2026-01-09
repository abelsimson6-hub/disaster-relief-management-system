import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:relief/app_state.dart';
import 'package:relief/screens/splash_screen.dart';
import 'package:relief/screens/welcome_screen.dart';
import 'package:relief/screens/register_placeholder.dart';
import 'package:relief/screens/profile_screen.dart';
import 'package:relief/screens/request_details.dart';
import 'package:relief/screens/camp_admin_dashboard.dart';
import 'package:relief/screens/victim_dashboard.dart';
import 'package:relief/screens/volunteer_dashboard.dart';
import 'package:relief/screens/donor_dashboard.dart';
import 'package:relief/screens/admin_dashboard.dart';
import 'package:relief/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ReliefConnect',
            theme: ThemeData(primarySwatch: Colors.blue),
            home: _screenFor(appState),
          );
        },
      ),
    );
  }

  Widget _screenFor(AppState appState) {
    switch (appState.currentScreen) {
      case Screen.splash:
        return const SplashScreen();
      case Screen.welcome:
        return const WelcomeScreen();
      case Screen.register:
        return RegisterPlaceholder(onNavigateToLogin: () => appState.handleNavigateToLogin());
      case Screen.login:
        return LoginScreen(onNavigateToRegister: () => appState.handleNavigateToRegister());
      case Screen.profile:
        return ProfileScreen(onBack: () => appState.handleBackFromProfile(), onLogout: () => appState.handleLogout(), role: appState.userRole);
      case Screen.requestDetails:
        return RequestDetails(onBack: () => appState.handleBackFromDetails());
      case Screen.campAdminDashboard:
        return CampAdminDashboard(onNavigateToProfile: () => appState.handleNavigateToProfile());
      case Screen.victimDashboard:
        return VictimDashboard(onNavigateToProfile: () => appState.handleNavigateToProfile());
      case Screen.volunteerDashboard:
        return VolunteerDashboard(onNavigateToProfile: () => appState.handleNavigateToProfile());
      case Screen.donorDashboard:
        return DonorDashboard(onNavigateToProfile: () => appState.handleNavigateToProfile());
      case Screen.adminDashboard:
        return AdminDashboard(onNavigateToProfile: () => appState.handleNavigateToProfile());
      default:
        return const WelcomeScreen();
    }
  }
}
