// API Service Layer for backend integration
// Handles JWT authentication, token refresh, and API calls
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart' show TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:relief/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Get base URL based on platform
  // - Web/Desktop: Use localhost (127.0.0.1)
  // - Android Emulator: Use 10.0.2.2 (special IP to access host's localhost)
  // - iOS Simulator: Use localhost (127.0.0.1)
  static String get baseUrl {
    if (kIsWeb) {
      // Web platform - use localhost
      return 'http://localhost:8000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator - use special IP to access host machine's localhost
      return 'http://10.0.2.2:8000/api';
    } else {
      // iOS, Desktop (Windows, Linux, macOS) - use localhost
      return 'http://localhost:8000/api';
    }
  }
  
  // Token storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _userRoleKey = 'user_role';

  // Get stored access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Get stored refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Save tokens to storage
  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  // Save user info
  static Future<void> saveUserInfo(int userId, String username, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_userRoleKey, role);
  }

  // Get user info
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);
    final username = prefs.getString(_usernameKey);
    final role = prefs.getString(_userRoleKey);
    
    if (userId != null && username != null && role != null) {
      return {
        'id': userId,
        'username': username,
        'role': role,
      };
    }
    return null;
  }

  // Clear all stored data (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_userRoleKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Refresh access token using refresh token
  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'] as String;
        final currentRefreshToken = await getRefreshToken();
        if (currentRefreshToken != null) {
          await saveTokens(newAccessToken, currentRefreshToken);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Make authenticated request with automatic token refresh
  static Future<http.Response> authenticatedRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    String? token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    // Prepare headers
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      ...?headers,
    };

    // Make request
    http.Response response;
    final uri = Uri.parse('$baseUrl$endpoint');
    
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: requestHeaders);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PATCH':
        response = await http.patch(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: requestHeaders);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    // If token expired (401), try to refresh and retry once
    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        token = await getAccessToken();
        if (token != null) {
          requestHeaders['Authorization'] = 'Bearer $token';
          // Retry the request with new token
          switch (method.toUpperCase()) {
            case 'GET':
              response = await http.get(uri, headers: requestHeaders);
              break;
            case 'POST':
              response = await http.post(
                uri,
                headers: requestHeaders,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'PUT':
              response = await http.put(
                uri,
                headers: requestHeaders,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'PATCH':
              response = await http.patch(
                uri,
                headers: requestHeaders,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'DELETE':
              response = await http.delete(uri, headers: requestHeaders);
              break;
          }
        }
      } else {
        // Token refresh failed, clear tokens and throw exception
        await clearAll();
        throw Exception('Authentication failed. Please login again.');
      }
    }

    return response;
  }

  // ==================== Authentication Methods ====================

  // Login and get JWT tokens
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final accessToken = data['access'] as String?;
          final refreshToken = data['refresh'] as String?;
          
          if (accessToken == null || refreshToken == null) {
            return {
              'success': false,
              'error': 'Invalid response from server: missing tokens',
            };
          }
          
          // Save tokens
          await saveTokens(accessToken, refreshToken);

          return {
            'success': true,
            'message': 'Login successful',
            'access': accessToken,
            'refresh': refreshToken,
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Failed to parse server response: ${e.toString()}',
          };
        }
      } else {
        String errorMessage = 'Login failed';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['detail'] ?? 
                          errorData['error'] ?? 
                          errorData['message'] ?? 
                          'Login failed (Status: ${response.statusCode})';
          } else {
            errorMessage = 'Login failed (Status: ${response.statusCode})';
          }
        } catch (e) {
          errorMessage = 'Login failed (Status: ${response.statusCode})';
        }
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'error': 'Cannot connect to server. Please make sure the backend is running at $baseUrl',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Register new user
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );

      if (response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          // If tokens are provided during registration, save them
          if (data['access'] != null && data['refresh'] != null) {
            await saveTokens(data['access'] as String, data['refresh'] as String);
            // Save user info if available
            if (data['user_id'] != null && data['username'] != null && data['role'] != null) {
              await saveUserInfo(
                data['user_id'] as int,
                data['username'] as String,
                data['role'] as String,
              );
            }
          }
          return {
            'success': true,
            'message': data['message'] ?? 'Registration successful',
            'user_id': data['user_id'],
            'access': data['access'],
            'refresh': data['refresh'],
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Failed to parse server response: ${e.toString()}',
          };
        }
      } else {
        String errorMessage = 'Registration failed';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['error'] ?? 
                          errorData['detail'] ?? 
                          errorData['message'] ?? 
                          'Registration failed (Status: ${response.statusCode})';
          } else {
            errorMessage = 'Registration failed (Status: ${response.statusCode})';
          }
        } catch (e) {
          errorMessage = 'Registration failed (Status: ${response.statusCode})';
        }
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'error': 'Cannot connect to server. Please make sure the backend is running at $baseUrl',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await authenticatedRequest('/user/profile/');
      if (response.statusCode == 200) {
        try {
          final profileData = jsonDecode(response.body);
          // Handle both new consistent structure and legacy structure
          if (profileData is Map<String, dynamic>) {
            if (profileData['data'] != null) {
              // New structure with success/data wrapper
              return {
                'success': true,
                'data': profileData['data'],
                'user': profileData['user'],
                'role': profileData['role'],
              };
            } else {
              // Direct profile data
              return {
                'success': true,
                'data': profileData,
              };
            }
          }
          return {
            'success': true,
            'data': profileData,
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Failed to parse profile data: ${e.toString()}',
          };
        }
      } else {
        String errorMessage = 'Failed to get profile';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['error'] ?? 
                          errorData['detail'] ?? 
                          'Failed to get profile (Status: ${response.statusCode})';
          }
        } catch (e) {
          // Ignore JSON parse errors for error messages
        }
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== Help Request (SOS) Methods ====================

  // Get help requests (for victims: their own, for others: all)
  static Future<Map<String, dynamic>> getHelpRequests({String? status}) async {
    try {
      String endpoint = '/sos-requests/';
      if (status != null && status.isNotEmpty && status == 'pending') {
        endpoint = '/sos-requests/pending/';
      }
      final response = await authenticatedRequest(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle paginated response from DRF
        if (data is Map && data.containsKey('results')) {
          return {
            'success': true,
            'data': data['results'] as List,
          };
        } else if (data is List) {
          return {
            'success': true,
            'data': data,
          };
        } else {
          return {
            'success': true,
            'data': [data],
          };
        }
      } else {
        String errorMessage = 'Failed to get help requests';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['error'] ?? 
                          errorData['detail'] ?? 
                          errorMessage;
          }
        } catch (e) {
          // Ignore parse errors
        }
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Create help request
  static Future<Map<String, dynamic>> createHelpRequest({
    required int disasterId,
    required String description,
    required String location,
  }) async {
    try {
      final response = await authenticatedRequest(
        '/sos-requests/',
        method: 'POST',
        body: {
          'disasters': disasterId,
          'description': description,
          'location': location,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData.toString(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update help request status
  static Future<Map<String, dynamic>> updateHelpRequestStatus(
    int requestId,
    String status,
  ) async {
    try {
      final response = await authenticatedRequest(
        '/sos-requests/$requestId/',
        method: 'PATCH',
        body: {'status': status},
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to update status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== Task Assignment Methods ====================

  // Get tasks (for volunteers)
  static Future<Map<String, dynamic>> getTasks({String? filter}) async {
    try {
      String endpoint = filter == 'my_tasks' ? '/tasks/my_tasks/' : '/tasks/';
      final response = await authenticatedRequest(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data is List ? data : (data['results'] ?? data),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get tasks',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update task status
  static Future<Map<String, dynamic>> updateTaskStatus(
    int taskId,
    String status,
  ) async {
    try {
      final response = await authenticatedRequest(
        '/tasks/$taskId/',
        method: 'PATCH',
        body: {'status': status},
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to update task',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== Donation Methods ====================

  // Get donations
  static Future<Map<String, dynamic>> getDonations() async {
    try {
      final response = await authenticatedRequest('/donations/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle paginated response from DRF
        if (data is Map && data.containsKey('results')) {
          return {
            'success': true,
            'data': data['results'] as List,
          };
        } else if (data is List) {
          return {
            'success': true,
            'data': data,
          };
        } else {
          return {
            'success': true,
            'data': [data],
          };
        }
      } else {
        String errorMessage = 'Failed to get donations';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['error'] ?? 
                          errorData['detail'] ?? 
                          errorMessage;
          }
        } catch (e) {
          // Ignore parse errors
        }
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Create donation
  static Future<Map<String, dynamic>> createDonation({
    required String donorName,
    required String donorType,
    String? contactEmail,
    String? contactPhone,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      final body = {
        'donor_name': donorName,
        'donor_type': donorType,
        if (contactEmail != null) 'contact_email': contactEmail,
        if (contactPhone != null) 'contact_phone': contactPhone,
        if (items != null) 'items': items,
      };
      final response = await authenticatedRequest(
        '/donations/',
        method: 'POST',
        body: body,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData.toString(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== Disaster Methods ====================

  // Get disasters
  static Future<Map<String, dynamic>> getDisasters() async {
    try {
      final response = await authenticatedRequest('/disasters/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle paginated response from DRF
        if (data is Map && data.containsKey('results')) {
          return {
            'success': true,
            'data': data['results'] as List,
          };
        } else if (data is List) {
          return {
            'success': true,
            'data': data,
          };
        } else {
          return {
            'success': true,
            'data': [data],
          };
        }
      } else {
        String errorMessage = 'Failed to get disasters';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['error'] ?? 
                          errorData['detail'] ?? 
                          errorMessage;
          }
        } catch (e) {
          // Ignore parse errors
        }
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== Camp Methods ====================

  // Get camps
  static Future<Map<String, dynamic>> getCamps() async {
    try {
      final response = await authenticatedRequest('/camps/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle paginated response from DRF
        if (data is Map && data.containsKey('results')) {
          return {
            'success': true,
            'data': data['results'] as List,
          };
        } else if (data is List) {
          return {
            'success': true,
            'data': data,
          };
        } else {
          return {
            'success': true,
            'data': [data],
          };
        }
      } else {
        String errorMessage = 'Failed to get camps';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['error'] ?? 
                          errorData['detail'] ?? 
                          errorMessage;
          }
        } catch (e) {
          // Ignore parse errors
        }
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== Admin Methods ====================

  // Get admin dashboard data
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final response = await authenticatedRequest('/admin/dashboard/');
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get admin dashboard',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
 
 
  // ==================== Profile (Typed API) ====================

  static Future<UserProfile> fetchProfile() async {
    final response = await authenticatedRequest('/user/profile/');

    if (response.statusCode != 200) {
      throw Exception('Failed to load profile');
    }

    final decoded = jsonDecode(response.body);

    final data = decoded is Map && decoded.containsKey('data')
        ? decoded['data']
        : decoded;

    return UserProfile.fromJson(data);
  }
}




 

