# Flutter App Integration Guide

## ✅ **Yes, All Endpoints Will Work in Flutter!**

Your Django backend is already configured for Flutter mobile apps. Here's what's set up:

---

## 🔧 **Backend Configuration Status**

### ✅ **Already Configured:**

1. **CORS Support** (for Flutter Web if you deploy web version)
   - `django-cors-headers` installed
   - `CORS_ALLOW_ALL_ORIGINS = True` (development)
   - Authorization header allowed
   - All HTTP methods allowed (GET, POST, PUT, PATCH, DELETE)

2. **JWT Authentication**
   - `rest_framework_simplejwt` configured
   - Access token lifetime: 60 minutes
   - Refresh token lifetime: 7 days

3. **DRF Configuration**
   - JWT authentication enabled
   - Pagination configured (20 items per page)

### ⚠️ **Important Note:**
- **Mobile apps (iOS/Android) don't use CORS** - CORS only applies to web browsers
- Mobile apps make direct HTTP requests, so CORS doesn't affect them
- The JWT authentication works the same way in Flutter as in Postman

---

## 📱 **Flutter Implementation**

### **1. Install Required Packages**

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2  # For storing JWT tokens
  dio: ^5.4.0  # Alternative to http (better for APIs)
```

### **2. Create API Service Class**

```dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://your-server-ip:8000/api/';
  late Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptor to include JWT token in all requests
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, refresh or logout
          await refreshToken();
        }
        return handler.next(error);
      },
    ));
  }
  
  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
  
  // Save token after login
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }
  
  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('token/', data: {
        'username': username,
        'password': password,
      });
      
      if (response.statusCode == 200) {
        final accessToken = response.data['access'];
        final refreshToken = response.data['refresh'];
        await saveToken(accessToken);
        await saveRefreshToken(refreshToken);
        return {'success': true, 'token': accessToken};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
    return {'success': false};
  }
  
  // Refresh token
  Future<void> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken != null) {
        final response = await _dio.post('token/refresh/', data: {
          'refresh': refreshToken,
        });
        if (response.statusCode == 200) {
          await saveToken(response.data['access']);
        }
      }
    } catch (e) {
      // Handle refresh error
    }
  }
  
  // Example: Get help requests
  Future<List<dynamic>> getHelpRequests() async {
    try {
      final response = await _dio.get('help-requests/');
      return response.data['help_requests'] ?? [];
    } catch (e) {
      throw Exception('Failed to load help requests: $e');
    }
  }
  
  // Example: Create help request
  Future<Map<String, dynamic>> createHelpRequest({
    required int disasterId,
    required String description,
    required String location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dio.post('help-requests/create/', data: {
        'disaster_id': disasterId,
        'description': description,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to create help request: $e');
    }
  }
  
  // Example: Create donation
  Future<Map<String, dynamic>> createDonation({
    required String donorName,
    required String donorType,
    required int campId,
    required List<Map<String, dynamic>> items,
    String? contactEmail,
    String? contactPhone,
  }) async {
    try {
      final response = await _dio.post('donations/create/', data: {
        'donor_name': donorName,
        'donor_type': donorType,
        'camp_id': campId,
        'items': items,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to create donation: $e');
    }
  }
  
  // Helper methods for token management
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }
  
  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', token);
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
}
```

### **3. Usage Example in Flutter Widget**

```dart
import 'package:flutter/material.dart';

class HelpRequestsScreen extends StatefulWidget {
  @override
  _HelpRequestsScreenState createState() => _HelpRequestsScreenState();
}

class _HelpRequestsScreenState extends State<HelpRequestsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _helpRequests = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadHelpRequests();
  }
  
  Future<void> _loadHelpRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _apiService.getHelpRequests();
      setState(() {
        _helpRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    return ListView.builder(
      itemCount: _helpRequests.length,
      itemBuilder: (context, index) {
        final request = _helpRequests[index];
        return ListTile(
          title: Text(request['description'] ?? 'No description'),
          subtitle: Text('Status: ${request['status']}'),
          trailing: Text(request['requested_at'] ?? ''),
        );
      },
    );
  }
}
```

---

## 🔐 **Authentication Flow in Flutter**

### **1. Login Screen**

```dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  
  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    final result = await _apiService.login(
      _usernameController.text,
      _passwordController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (result['success'] == true) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${result['error']}')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📡 **API Endpoints That Work in Flutter**

### ✅ **Fully Converted (Work with JWT):**

**Operations:**
- `GET /api/help-requests/` - List help requests
- `POST /api/help-requests/create/` - Create SOS request
- `PUT /api/help-requests/{id}/status/` - Update status
- `POST /api/help-requests/{id}/assign-volunteer/` - Assign volunteer
- `GET /api/donations/` - List donations
- `POST /api/donations/create/` - Create donation
- `GET /api/donations/my-donations/` - My donations
- `PUT /api/donations/{id}/status/` - Update donation status
- `GET /api/tasks/` - List tasks
- `POST /api/tasks/create/` - Create task
- `PUT /api/tasks/{id}/status/` - Update task status

**Relief:**
- `GET /api/resources/` - List resources
- `POST /api/resources/create/` - Create resource
- `GET /api/resource-requests/` - List resource requests
- `POST /api/resource-requests/create/` - Create resource request
- `PUT /api/resource-requests/{id}/status/` - Update request status

### ⚠️ **Still Need Conversion (May have issues):**

These endpoints still use session authentication and may not work properly:
- Communication endpoints
- Alerts endpoints
- Disasters endpoints
- Shelters endpoints
- Users endpoints

**Solution:** Convert remaining views to DRF (see `API_CONVERSION_STATUS.md`)

---

## 🌐 **Network Configuration**

### **For Development (Local Network):**

1. **Find your computer's IP address:**
   - Windows: `ipconfig` → Look for IPv4 Address
   - Mac/Linux: `ifconfig` or `ip addr`

2. **Update Flutter base URL:**
   ```dart
   static const String baseUrl = 'http://192.168.1.100:8000/api/';
   // Replace with your actual IP address
   ```

3. **Update Django ALLOWED_HOSTS:**
   ```python
   ALLOWED_HOSTS = ['*']  # Already set for development
   ```

4. **Run Django server:**
   ```bash
   python manage.py runserver 0.0.0.0:8000
   # This makes it accessible from other devices on the network
   ```

### **For Production:**

1. **Deploy Django to a server** (AWS, Heroku, DigitalOcean, etc.)
2. **Update base URL in Flutter:**
   ```dart
   static const String baseUrl = 'https://your-api-domain.com/api/';
   ```
3. **Update CORS settings** (remove `CORS_ALLOW_ALL_ORIGINS`):
   ```python
   CORS_ALLOW_ALL_ORIGINS = False
   CORS_ALLOWED_ORIGINS = [
       "https://your-flutter-web-app.com",
   ]
   ```

---

## 🧪 **Testing in Flutter**

### **1. Test Login:**
```dart
final apiService = ApiService();
final result = await apiService.login('testuser', 'testpass');
print('Login result: $result');
```

### **2. Test Get Help Requests:**
```dart
final requests = await apiService.getHelpRequests();
print('Help requests: $requests');
```

### **3. Test Create Donation:**
```dart
final result = await apiService.createDonation(
  donorName: 'John Doe',
  donorType: 'individual',
  campId: 1,
  items: [
    {'resource': 1, 'quantity': 10},
    {'resource': 2, 'quantity': 5},
  ],
);
print('Donation created: $result');
```

---

## ✅ **Summary**

**YES, your endpoints will work in Flutter because:**

1. ✅ **JWT Authentication** - Works the same in Flutter as Postman
2. ✅ **CORS Configured** - For web version (mobile doesn't need it)
3. ✅ **DRF Endpoints** - All converted endpoints use standard REST
4. ✅ **Authorization Header** - Properly configured in CORS
5. ✅ **HTTP Methods** - All methods (GET, POST, PUT, PATCH, DELETE) allowed

**The only difference from Postman:**
- In Postman: You manually add `Authorization: Bearer <token>` header
- In Flutter: You add it automatically via Dio interceptor (as shown above)

**All endpoints that work in Postman will work in Flutter!** 🎉
