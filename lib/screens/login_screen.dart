// lib/src/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:relief/app_state.dart';
import '../widgets/app_layout.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onNavigateToRegister;
  final RoleType selectedRole;

  const LoginScreen({
    super.key,
    required this.onNavigateToRegister,
    required this.selectedRole,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _animController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    // Start entrance animation
    _animController.forward();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final appState = Provider.of<AppState>(context, listen: false);
      await appState.handleLogin(_usernameCtrl.text.trim(), _passwordCtrl.text);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = appState.errorMessage;
        });
      }
    }
  }

  String _roleLabel(RoleType role) {
    switch (role) {
      case RoleType.donor:
        return 'Donor';
      case RoleType.volunteer:
        return 'Volunteer';
      case RoleType.admin:
        return 'Admin';
      case RoleType.campAdmin:
        return 'Camp Admin';
      case RoleType.victim:
        return 'Victim';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF007BFF);

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AppLayout(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Welcome Back',
                              style: TextStyle(
                                color: primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sign in to ReliefConnect',
                              style: TextStyle(color: Colors.grey[600]),
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
                                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Username field
                            TextFormField(
                              controller: _usernameCtrl,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.person),
                                labelText: 'Username',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter username';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Password field
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
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Enter password'
                                  : null,
                            ),

                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: Forgot password flow
                                },
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(color: primary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Login button with trailing arrow
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _handleLogin,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.arrow_forward),
                              label: Text(_isLoading ? 'Logging in...' : 'Login'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Register (outlined) button
                            OutlinedButton(
                              onPressed: widget.onNavigateToRegister,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                side: BorderSide(color: primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Register',
                                style: TextStyle(color: primary),
                              ),
                            ),

                            const SizedBox(height: 12),
                            Text(
                              'Together we can make a difference',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),

                            // small hint about selected role (optional)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Logging in as: ${_roleLabel(widget.selectedRole)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
