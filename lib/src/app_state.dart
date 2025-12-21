import 'package:flutter/material.dart';

enum Screen {
  splash,
  welcome,
  roleSelection,
  login,
  register,
  victimDashboard,
  volunteerDashboard,
  donorDashboard,
  adminDashboard,
  campAdminDashboard,
  requestDetails,
  donationDetails,
  map,
  profile,
}

enum RoleType { victim, donor, volunteer, admin, campAdmin }

class AppState extends ChangeNotifier {
  Screen currentScreen = Screen.splash;
  RoleType userRole = RoleType.victim;
  Screen previousScreen = Screen.victimDashboard;

  void _setScreen(Screen screen) {
    currentScreen = screen;
    notifyListeners();
  }

  void handleSplashComplete() => _setScreen(Screen.roleSelection);

  void handleRoleSelection(RoleType role) {
    userRole = role;
    _setScreen(Screen.login);
  }

  void handleLogin(RoleType role) {
    userRole = role;
    navigateToDashboard(role);
  }

  void navigateToDashboard(RoleType role) {
    switch (role) {
      case RoleType.victim:
        _setScreen(Screen.victimDashboard);
        previousScreen = Screen.victimDashboard;
        break;
      case RoleType.donor:
        _setScreen(Screen.donorDashboard);
        previousScreen = Screen.donorDashboard;
        break;
      case RoleType.volunteer:
        _setScreen(Screen.volunteerDashboard);
        previousScreen = Screen.volunteerDashboard;
        break;
      case RoleType.admin:
        _setScreen(Screen.adminDashboard);
        previousScreen = Screen.adminDashboard;
        break;
      case RoleType.campAdmin:
        _setScreen(Screen.campAdminDashboard);
        previousScreen = Screen.campAdminDashboard;
        break;
    }
  }

  void handleLogout() => _setScreen(Screen.roleSelection);

  void handleNavigateToRegister() => _setScreen(Screen.register);
  void handleNavigateToLogin() => _setScreen(Screen.login);
  void handleNavigateToProfile() => _setScreen(Screen.profile);
  void handleNavigateToRequestDetails() => _setScreen(Screen.requestDetails);
  void handleNavigateToDonationDetails() => _setScreen(Screen.donationDetails);
  void handleNavigateToMap() => _setScreen(Screen.map);
  void handleBackFromDetails() => _setScreen(previousScreen);
  void handleBackFromProfile() => _setScreen(previousScreen);

  void startRegistration(victim) {}
}
