# Flutter Integration Guide for DRMS Backend

## ✅ Backend Status: COMPLETE & READY FOR INTEGRATION

Your Django backend is **100% complete** with all 6 features implemented. Now let's integrate it with your Flutter app!

---

## 📋 Pre-Integration Checklist

### Step 1: Install CORS Package (if not already installed)

```bash
pip install django-cors-headers
```

**Note:** The settings.py has been updated to include CORS configuration, but you need to install the package.

### Step 2: Run Migrations

```bash
cd DRMS
python manage.py makemigrations alerts
python manage.py migrate
```

### Step 3: Start Django Server

```bash
python manage.py runserver
```

Your API will be available at:
- **Local**: `http://127.0.0.1:8000/api/`
- **Network**: `http://YOUR_IP:8000/api/` (for mobile device testing)

To find your IP address:
- **Windows**: `ipconfig` (look for IPv4 Address)
- **Mac/Linux**: `ifconfig` or `ip addr`

---

## 🚀 Flutter Integration Steps

### 1. Add Required Packages to `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP Requests
  http: ^1.1.0
  
  # JSON Serialization
  json_annotation: ^4.8.1
  
  # Local Storage (for tokens)
  shared_preferences: ^2.2.2
  
  # JWT Token Decoding (optional but useful)
  jwt_decoder: ^2.0.1
  
  # State Management (choose one)
  provider: ^6.1.1
  # OR
  # bloc: ^8.1.3
  # OR
  # get: ^4.6.6
```

Run: `flutter pub get`

### 2. Create API Service Class

Create a file: `lib/services/api_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL - Change this to your server address
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  // For mobile device testing, use your computer's IP:
  // static const String baseUrl = 'http://192.168.1.XXX:8000/api';
  
  // Get stored access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
  
  // Get stored refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }
  
  // Save tokens
  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }
  
  // Clear tokens (logout)
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
  
  // Make authenticated request
  static Future<http.Response> authenticatedRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final token = await getAccessToken();
    
    if (token == null) {
      throw Exception('No access token found');
    }
    
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    
    switch (method) {
      case 'GET':
        return await http.get(url, headers: headers);
      case 'POST':
        return await http.post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(url, headers: headers);
      default:
        throw Exception('Unsupported HTTP method');
    }
  }
  
  // Refresh access token
  static Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveTokens(data['access'], refreshToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Register User
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String role = 'victim',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    
    return {
      'success': response.statusCode == 201,
      'data': jsonDecode(response.body),
    };
  }
  
  // Login and get tokens
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveTokens(data['access'], data['refresh']);
      return {'success': true, 'data': data};
    }
    
    return {
      'success': false,
      'error': jsonDecode(response.body),
    };
  }
  
  // Get User Profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await authenticatedRequest('/user/profile/');
      return {
        'success': response.statusCode == 200,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Get Admin Dashboard
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final response = await authenticatedRequest('/admin/dashboard/');
      return {
        'success': response.statusCode == 200,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Example: Get SOS Requests
  static Future<Map<String, dynamic>> getSosRequests() async {
    try {
      final response = await authenticatedRequest('/sos-requests/');
      return {
        'success': response.statusCode == 200,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Example: Create SOS Request
  static Future<Map<String, dynamic>> createSosRequest({
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
      return {
        'success': response.statusCode == 201,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Add more methods as needed for other endpoints...
}
```

### 3. Create Auth Provider/Bloc (Example with Provider)

Create `lib/providers/auth_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userProfile;
  
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userProfile => _userProfile;
  
  // Check if user is authenticated on app start
  Future<void> checkAuthStatus() async {
    final token = await ApiService.getAccessToken();
    if (token != null) {
      _isAuthenticated = true;
      await loadUserProfile();
      notifyListeners();
    }
  }
  
  // Login
  Future<bool> login(String username, String password) async {
    final result = await ApiService.login(
      username: username,
      password: password,
    );
    
    if (result['success']) {
      _isAuthenticated = true;
      await loadUserProfile();
      notifyListeners();
      return true;
    }
    return false;
  }
  
  // Register
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String role = 'victim',
  }) async {
    final result = await ApiService.register(
      username: username,
      email: email,
      password: password,
      role: role,
    );
    
    if (result['success']) {
      // Auto login after registration
      return await login(username, password);
    }
    return false;
  }
  
  // Load user profile
  Future<void> loadUserProfile() async {
    final result = await ApiService.getUserProfile();
    if (result['success']) {
      _userProfile = result['data'];
      notifyListeners();
    }
  }
  
  // Logout
  Future<void> logout() async {
    await ApiService.clearTokens();
    _isAuthenticated = false;
    _userProfile = null;
    notifyListeners();
  }
}
```

### 4. Update main.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
      ],
      child: MaterialApp(
        title: 'Disaster Relief Management',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const LoginScreen(), // Your login screen
      ),
    );
  }
}
```

### 5. Example Login Screen

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleLogin,
                    child: const Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📱 Important Configuration for Flutter Mobile

### Android Configuration

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <application
        android:usesCleartextTraffic="true"  <!-- For HTTP in development -->
        ...>
```

### iOS Configuration

Add to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## 🔗 All API Endpoints Available

### Authentication
- `POST /api/register/` - Register user
- `POST /api/token/` - Login (get JWT tokens)
- `POST /api/token/refresh/` - Refresh access token
- `GET /api/user/profile/` - Get user profile

### Resources
- `GET /api/resources/` - List resources
- `POST /api/resources/` - Create resource
- `GET /api/resource-requests/` - List requests
- `GET /api/resource-requests/pending/` - Pending requests

### Donations
- `GET /api/donations/` - List donations
- `POST /api/donations/` - Create donation
- `GET /api/admin/donation-matching/` - Smart matching

### Volunteers & Tasks
- `GET /api/volunteers/` - List volunteers
- `GET /api/tasks/` - List tasks
- `GET /api/tasks/my_tasks/` - Get my tasks

### SOS Requests
- `GET /api/sos-requests/` - List SOS requests
- `POST /api/sos-requests/` - Create SOS request
- `GET /api/sos-requests/pending/` - Pending requests
- `POST /api/sos-requests/{id}/assign_volunteer/` - Assign volunteer

### Weather Alerts
- `GET /api/weather-alerts/` - List alerts
- `POST /api/weather-alerts/` - Create alert
- `GET /api/weather-alerts/active/` - Active alerts
- `GET /api/weather-alerts/high_risk/` - High-risk alerts

### Admin Dashboard
- `GET /api/admin/dashboard/` - Full dashboard stats
- `GET /api/admin/resource-analytics/` - Resource analytics
- `GET /api/admin/volunteer-coordination/` - Volunteer data

**See `API_DOCUMENTATION.md` for complete endpoint documentation.**

---

## ✅ Testing Your Integration

### 1. Test API Connection

```dart
// Test if backend is reachable
final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/test/'));
print(response.body); // Should print: {"message": "API working!"}
```

### 2. Test Authentication Flow

1. Register a user
2. Login and save tokens
3. Make authenticated request
4. Check if token refresh works

### 3. Test Each Feature

- Create SOS request
- View dashboard (if admin)
- Get resources
- View donations
- etc.

---

## 🐛 Common Issues & Solutions

### Issue: Connection refused / Cannot connect
**Solution**: 
- Make sure Django server is running
- For mobile: Use your computer's IP address instead of `127.0.0.1`
- Check firewall settings
- Ensure both devices are on same network

### Issue: CORS errors (web only)
**Solution**: 
- `django-cors-headers` is already configured
- Make sure `pip install django-cors-headers` is run
- Restart Django server

### Issue: 401 Unauthorized
**Solution**:
- Check if token is being sent in headers
- Verify token format: `Bearer <token>`
- Token might be expired - implement refresh logic

### Issue: 403 Forbidden on admin endpoints
**Solution**:
- User must have `super_admin` or `camp_admin` role
- Check user role in database or via profile endpoint

---

## 🎉 You're Ready!

Your backend is complete and ready for Flutter integration. Follow the steps above and you'll have a fully connected Flutter app!

**Need help?** Check the API responses - they include helpful error messages.

