import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:relief/src/screens/admin_dashboard.dart';
import 'package:relief/src/screens/donation_details.dart';
import 'package:relief/src/screens/donor_dashboard.dart';
import 'package:relief/src/screens/login_screen.dart';
import 'package:relief/src/screens/map_screen.dart';
import 'package:relief/src/screens/profile_screen.dart';
import 'package:relief/src/screens/register_screen.dart';
import 'package:relief/src/screens/request_details.dart';
import 'package:relief/src/screens/role_selection_screen.dart';
import 'package:relief/src/screens/splash_screen.dart';
import 'package:relief/src/screens/victim_dashboard.dart';
import 'package:relief/src/screens/volunteer_dashboard.dart';
import 'app_state.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReliefConnect',
      theme: ThemeData(
        primaryColor: Color(0xFF007BFF),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.blueAccent,
        ),
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: AppBarTheme(backgroundColor: Color(0xFF007BFF)),
      ),
      home: SafeArea(
        child: Container(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420),
            child: Builder(
              builder: (context) {
                switch (appState.currentScreen) {
                  case Screen.splash:
                    return SplashScreen(
                      onComplete: appState.handleSplashComplete,
                    );
                  case Screen.roleSelection:
                    return RoleSelectionScreen(
                      onSelectRole: appState.handleRoleSelection,
                    );
                  case Screen.login:
                    return LoginScreen(
                      onLogin: appState.handleLogin,
                      onNavigateToRegister: appState.handleNavigateToRegister,
                      selectedRole: appState.userRole,
                    );
                  case Screen.register:
                    return RegisterScreen(
                      onNavigateToLogin: appState.handleNavigateToLogin,
                    );
                  case Screen.victimDashboard:
                    return VictimDashboard(
                      onNavigateToMap: appState.handleNavigateToMap,
                      onNavigateToProfile: appState.handleNavigateToProfile,
                      onNavigateToRequestDetails:
                          appState.handleNavigateToRequestDetails,
                    );
                  case Screen.donorDashboard:
                    return DonorDashboard(
                      onNavigateToMap: appState.handleNavigateToMap,
                      onNavigateToProfile: appState.handleNavigateToProfile,
                      onNavigateToDonationDetails:
                          appState.handleNavigateToDonationDetails,
                    );
                  case Screen.volunteerDashboard:
                    return VolunteerDashboard(
                      onNavigateToMap: appState.handleNavigateToMap,
                      onNavigateToProfile: appState.handleNavigateToProfile,
                      onNavigateToRequestDetails:
                          appState.handleNavigateToRequestDetails,
                    );
                  case Screen.adminDashboard:
                    return AdminDashboard(
                      onNavigateToProfile: appState.handleNavigateToProfile,
                    );
                  case Screen.requestDetails:
                    return RequestDetails(
                      onBack: appState.handleBackFromDetails,
                    );
                  case Screen.donationDetails:
                    return DonationDetailsScreen(
                      onBack: appState.handleBackFromDetails,
                    );
                  case Screen.map:
                    return MapScreen(onBack: appState.handleBackFromDetails);
                  case Screen.profile:
                    return ProfileScreen(
                      onBack: appState.handleBackFromProfile,
                      onLogout: appState.handleLogout,
                      role: appState.userRole,
                    );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
