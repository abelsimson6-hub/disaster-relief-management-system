import 'package:flutter/material.dart';
import 'package:relief/src/services/api_service.dart';

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
  bool isLoading = false;
  String? errorMessage;

  // Convert backend role string to RoleType enum
  static RoleType roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'victim':
        return RoleType.victim;
      case 'donor':
        return RoleType.donor;
      case 'volunteer':
        return RoleType.volunteer;
      case 'super_admin':
        return RoleType.admin;
      case 'camp_admin':
        return RoleType.campAdmin;
      default:
        return RoleType.victim;
    }
  }

  // Convert RoleType enum to backend role string
  static String roleToString(RoleType role) {
    switch (role) {
      case RoleType.victim:
        return 'victim';
      case RoleType.donor:
        return 'donor';
      case RoleType.volunteer:
        return 'volunteer';
      case RoleType.admin:
        return 'super_admin';
      case RoleType.campAdmin:
        return 'camp_admin';
    }
  }

  void _setScreen(Screen screen) {
    currentScreen = screen;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    errorMessage = error;
    notifyListeners();
  }

  // Check authentication status on app start
  Future<void> checkAuthStatus() async {
    final isLoggedIn = await ApiService.isLoggedIn();
    if (isLoggedIn) {
      final userInfo = await ApiService.getUserInfo();
      if (userInfo != null) {
        userRole = roleFromString(userInfo['role'] ?? 'victim');
        navigateToDashboard(userRole);
      } else {
        _setScreen(Screen.roleSelection);
      }
    } else {
      _setScreen(Screen.roleSelection);
    }
  }

  void handleSplashComplete() async {
    await checkAuthStatus();
    if (currentScreen == Screen.splash) {
      _setScreen(Screen.roleSelection);
    }
  }

  void handleRoleSelection(RoleType role) {
    userRole = role;
    _setScreen(Screen.login);
  }

  // Handle login with API call
  Future<void> handleLogin(String username, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.login(username, password);
      
      if (result['success'] == true) {
        // Get user profile to determine role and save user info
        final profileResult = await ApiService.getUserProfile();
        if (profileResult['success'] == true) {
          final profileData = profileResult['data'];
          // Extract role and user info from profile data (structure varies by role type)
          String roleStr = 'victim';
          int? userId;
          String usernameFromProfile = username;
          
          if (profileData['user'] != null) {
            // For role-specific profiles (volunteer, victim, camp_admin)
            userId = profileData['user']['id'];
            usernameFromProfile = profileData['user']['username'] ?? username;
            roleStr = profileData['user']['role'] ?? 'victim';
          } else {
            // For basic user profiles (donor, super_admin)
            userId = profileData['id'];
            usernameFromProfile = profileData['username'] ?? username;
            roleStr = profileData['role'] ?? 'victim';
          }
          
          // Save user info
          if (userId != null) {
            await ApiService.saveUserInfo(userId, usernameFromProfile, roleStr);
          }
          
          userRole = roleFromString(roleStr);
          navigateToDashboard(userRole);
        } else {
          _setError('Login successful but could not fetch profile');
        }
      } else {
        _setError(result['error'] ?? 'Login failed');
      }
    } catch (e) {
      _setError('Login error: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
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

  // Handle logout - clear tokens and return to role selection
  Future<void> handleLogout() async {
    await ApiService.clearAll();
    _setScreen(Screen.roleSelection);
    userRole = RoleType.victim;
  }

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
