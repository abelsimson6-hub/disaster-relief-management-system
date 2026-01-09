import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:relief/app_state.dart';
import 'package:relief/screens/admin_dashboard.dart';
import 'package:relief/screens/camp_admin_dashboard.dart';
import 'package:relief/screens/donation_details.dart';
import 'package:relief/screens/donor_dashboard.dart';
import 'package:relief/screens/login_screen.dart';
import 'package:relief/screens/map_screen.dart';
import 'package:relief/screens/profile_screen.dart';
import 'package:relief/screens/register_screen.dart';
import 'package:relief/screens/request_details.dart';
import 'package:relief/screens/role_selection_screen.dart';
import 'package:relief/screens/splash_screen.dart';
import 'package:relief/screens/victim_dashboard.dart';
import 'package:relief/screens/volunteer_dashboard.dart';
import 'package:relief/screens/welcome_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const MyApp()),
  );
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
        primaryColor: const Color(0xFF007BFF),
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF007BFF)),
      ),

      home: SafeArea(
        child: Container(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Builder(
              builder: (context) {
                switch (appState.currentScreen) {
                  case Screen.splash:
                    return SplashScreen(
                      onComplete: appState.handleSplashComplete,
                    );

                  case Screen.welcome:
                    return const WelcomeScreen();

                  case Screen.roleSelection:
                    return RoleSelectionScreen(
                      onSelectRole: appState.handleRoleSelection,
                    );

                  case Screen.login:
                    return LoginScreen(
                      selectedRole: appState.userRole,
                      onNavigateToRegister: appState.handleNavigateToRegister,
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

                  case Screen.campAdminDashboard:
                    return CampAdminDashboard(
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
                      role: appState.userRole,
                      onBack: appState.handleBackFromProfile,
                      onLogout: appState.handleLogout,
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
