// lib/src/screens/register_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:relief/services/api_service.dart';
import 'package:relief/app_state.dart';
import '../widgets/app_layout.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onNavigateToLogin;
  const RegisterScreen({super.key, required this.onNavigateToLogin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(); // ADDED: Phone number field
  final _passwordCtrl = TextEditingController();

  String _role = 'victim';
  bool _success = false;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _redirectTimer;

  late final AnimationController _entranceController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
        );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _redirectTimer?.cancel();
    super.dispose();
  }

  void _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _success = false;
    });

    try {
      final result = await ApiService.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: _role,
      );

      if (mounted) {
        if (result['success'] == true) {
          // If tokens were returned (auto-login after registration)
          if (result['access'] != null && result['refresh'] != null) {
            // Tokens are already saved by ApiService.register
            // Get user profile to navigate to dashboard
            final profileResult = await ApiService.getUserProfile();
            if (profileResult['success'] == true && mounted) {
              final profileData = profileResult['data'];
              final roleStr = profileData['role'] ?? _role;
              // Get AppState and navigate to dashboard
              final appState = Provider.of<AppState>(context, listen: false);
              appState.userRole = AppState.roleFromString(roleStr);
              if (appState.userRole != null) {
                appState.navigateToDashboard(appState.userRole!);
              }
              return;
            }
          }
          // If no tokens, show success and redirect to login
          setState(() => _success = true);
          _redirectTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              widget.onNavigateToLogin();
            }
          });
        } else {
          setState(() {
            _errorMessage = result['error'] ?? 'Registration failed';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF007BFF);

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AppLayout(
            padding: EdgeInsets.zero,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _success
                  ? _buildSuccessView(primary)
                  : _buildForm(context, primary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(Color primary) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
      ),
      child: Column(
        key: const ValueKey('success'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.check_circle, size: 80, color: Colors.green.shade600),
          const SizedBox(height: 16),
          Text(
            'Registration Successful!',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Redirecting to login...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, Color primary) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          key: const ValueKey('form'),
          mainAxisSize: MainAxisSize.min,
          children: [
            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.onNavigateToLogin,
                icon: const Icon(Icons.arrow_left),
                label: const Text('Back to Login'),
                style: TextButton.styleFrom(foregroundColor: Colors.black87),
              ),
            ),
            const SizedBox(height: 6),

            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          color: primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Join ReliefConnect today',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 18),

                      // Error message display
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Username field (using name field for username)
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person),
                          labelText: 'Username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter username'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.mail),
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter email';
                          }
                          if (!v.contains('@')) {
                            return 'Enter valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Phone number (REQUIRED)
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.phone),
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter phone number';
                          }
                          // Basic phone validation
                          final phoneRegex = RegExp(r'^\+?1?\d{9,15}$');
                          if (!phoneRegex.hasMatch(v.trim())) {
                            return 'Enter valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Password
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Min 6 chars' : null,
                      ),
                      const SizedBox(height: 12),

                      // Role selection
                      DropdownButtonFormField<String>(
                        initialValue: _role,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'victim',
                            child: Text('Victim (Need Help)'),
                          ),
                          DropdownMenuItem(
                            value: 'donor',
                            child: Text('Donor (Give Aid)'),
                          ),
                          DropdownMenuItem(
                            value: 'volunteer',
                            child: Text('Volunteer'),
                          ),
                          DropdownMenuItem(
                            value: 'camp_admin',
                            child: Text('Camp Admin'),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _role = val ?? 'victim'),
                      ),
                      const SizedBox(height: 16),

                      // Sign Up button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading || _success
                              ? null
                              : _handleRegister,
                          style:
                              ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                              ).copyWith(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                      // gradient-like look using primary color
                                      return Colors.blue;
                                    }),
                              ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign Up'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
