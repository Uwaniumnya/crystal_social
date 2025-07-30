import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/local_user_store.dart';
import '../services/enhanced_push_notification_integration.dart';
import '../services/device_user_tracking_service.dart';
import 'dart:async';
import 'dart:math' as math;

class EnhancedLoginScreen extends StatefulWidget {
  final Function(String username) onLogin;
  const EnhancedLoginScreen({required this.onLogin, super.key});

  @override
  EnhancedLoginScreenState createState() => EnhancedLoginScreenState();
}

class EnhancedLoginScreenState extends State<EnhancedLoginScreen> 
    with TickerProviderStateMixin {
  
  // Controllers
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _crystalController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _crystalRotation;
  late Animation<double> _pulseAnimation;
  
  // State
  String? _error;
  String? _success;
  bool _loading = false;
  bool _isSignup = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;
  
  // Crystal theme colors
  final List<Color> _crystalColors = [
    const Color(0xFF8A2BE2), // Blue Violet
    const Color(0xFF9370DB), // Medium Purple
    const Color(0xFFBA55D3), // Medium Orchid
    const Color(0xFFDA70D6), // Orchid
    const Color(0xFFEE82EE), // Violet
    const Color(0xFFDDA0DD), // Plum
  ];
  
  // Floating particles data
  List<Particle> _particles = [];
  Timer? _particleTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _startParticleAnimation();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _crystalController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _crystalRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _crystalController, curve: Curves.linear),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _crystalController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 15; i++) {
      _particles.add(Particle.random());
    }
  }

  void _startParticleAnimation() {
    _particleTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        for (var particle in _particles) {
          particle.update();
        }
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _crystalController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _particleTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = '$username@crystal.app';

    if (username.isEmpty || password.isEmpty) {
      _showError("Please enter both username and password!");
      return;
    }

    if (username.length < 3) {
      _showError("Username must be at least 3 characters long!");
      return;
    }

    if (password.length < 6) {
      _showError("Password must be at least 6 characters long!");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final supabase = Supabase.instance.client;

    try {
      // Try to sign in
      final signInRes = await supabase.auth
          .signInWithPassword(email: email, password: password);

      final user = signInRes.user;
      if (user == null) {
        _showError("Login failed. Please check credentials.");
        return;
      }

      
      if (_rememberMe) {
        await EnhancedLocalUserStore.rememberUser(user.id);
      }

      // 🚀 ENHANCED: Track user login for smart auto-logout
      await DeviceUserTrackingService.instance.trackUserLogin(user.id);

      // Register device for push notifications
      await EnhancedPushNotificationIntegration.instance.onUserLogin(user.id);

      _showSuccess("Welcome back to Crystal Social! ✨");
      
      // Add haptic feedback
      HapticFeedback.lightImpact();
      
      await Future.delayed(const Duration(milliseconds: 1500));
      widget.onLogin(username);
      
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        _showError("Invalid username or password.");
      } else if (e.message.contains('User not found')) {
        _showError("User not found. Please sign up first.");
      } else {
        _showError("Auth error: ${e.message}");
      }
    } catch (e) {
      _showError("Unexpected error: ${e.toString()}");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signup() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError("Please fill in all fields!");
      return;
    }

    if (username.length < 3) {
      _showError("Username must be at least 3 characters long!");
      return;
    }

    if (password.length < 6) {
      _showError("Password must be at least 6 characters long!");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords don't match!");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final supabase = Supabase.instance.client;

    try {
      // Generate a properly formatted email that should pass validation
      // Using UUID-style format to ensure uniqueness and validity
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomId = (timestamp * 1000 + (username.hashCode.abs() % 1000)).toString();
      final validEmail = "user$randomId@mailinator.com";
      
      print('🔄 Starting signup process for user: $username');
      print('🔄 Generated valid email: $validEmail');
      
      // Step 1: Create auth user with properly formatted email
      final signUpRes = await supabase.auth.signUp(
        email: validEmail,
        password: password,
      );

      print('✅ Auth signup completed successfully!');
      print('✅ User ID: ${signUpRes.user?.id}');
      print('✅ Session exists: ${signUpRes.session?.accessToken != null}');

      final userId = signUpRes.user?.id;
      if (userId == null) {
        _showError("Signup failed - no user ID returned.");
        return;
      }

      // Step 2: Ensure authentication session is established
      print('🔄 Verifying authentication session...');
      
      // Wait for auth transaction to complete and verify session
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // Get current session to ensure we're authenticated
      final session = supabase.auth.currentSession;
      if (session == null) {
        _showError("Authentication session not established. Please try again.");
        return;
      }
      
      print('✅ Authentication session verified');
      print('✅ Session user ID: ${session.user.id}');
      
      // Step 3: Create public.users record with proper authentication context
      try {
        print('🔄 Creating public user profile for ID: $userId');
        
        final insertData = {
          'id': userId,
          'username': username,
          'email': validEmail,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'prefersDarkMode': false,
          'theme_color': 'kawaii_pink',
          'isOnline': true,
        };
        
        final insertResult = await supabase
            .from('users')
            .insert(insertData)
            .select()
            .single();
        
        print('✅ Public user profile created successfully!');
        print('✅ Profile data: $insertResult');
        
      } catch (dbError) {
        print('❌ Public profile creation error: $dbError');
        print('❌ Error type: ${dbError.runtimeType}');
        
        // Check for RLS policy violation (code 42501)
        if (dbError.toString().contains('42501') || 
            dbError.toString().contains('security policy') ||
            dbError.toString().contains('Unauthorized')) {
          print('🔄 RLS policy issue detected, trying alternative approach...');
          
          // Try creating with minimal data first
          try {
            await supabase.from('users').upsert({
              'id': userId,
              'username': username,
              'email': validEmail,
            });
            print('✅ Minimal profile created with upsert');
          } catch (fallbackError) {
            print('❌ Fallback also failed: $fallbackError');
            
            // Last resort: try with rpc function or direct API call
            try {
              print('🔄 Trying final fallback method...');
              await supabase.rpc('create_user_profile', params: {
                'user_id': userId,
                'user_name': username,
                'user_email': validEmail,
              });
              print('✅ Profile created via RPC function');
            } catch (rpcError) {
              print('❌ RPC method also failed: $rpcError');
              _showError("Profile creation failed due to database security policies. Please contact support or run the RLS fix script.");
              return;
            }
          }
        } else if (dbError.toString().contains('duplicate key') || 
            dbError.toString().contains('unique constraint')) {
          // User already exists, try to get existing data
          try {
            print('🔄 User may already exist, checking...');
            final existing = await supabase
                .from('users')
                .select()
                .eq('id', userId)
                .single();
            print('✅ Found existing user profile: $existing');
          } catch (e) {
            print('❌ Could not find existing user: $e');
            _showError("Username may already be taken. Please try a different one.");
            return;
          }
        } else if (dbError.toString().contains('relation "public.users" does not exist')) {
          _showError("Database setup incomplete. Please run FINAL_SIGNUP_FIX.sql first.");
          return;
        } else {
          // Try a minimal insert as fallback
          print('🔄 Trying minimal profile insert as fallback...');
          try {
            await supabase.from('users').upsert({
              'id': userId,
              'username': username,
              'email': validEmail,
            });
            print('✅ Minimal profile created with upsert');
          } catch (fallbackError) {
            print('❌ Fallback also failed: $fallbackError');
            _showError("Profile creation failed: ${fallbackError.toString()}");
            return;
          }
        }
      }
      
      // Step 4: Complete signup process
      if (_rememberMe) {
        await EnhancedLocalUserStore.rememberUser(userId);
      }
      
      // 🚀 ENHANCED: Track user login for smart auto-logout
      await DeviceUserTrackingService.instance.trackUserLogin(userId);
      
      // Register device for push notifications
      await EnhancedPushNotificationIntegration.instance.onUserLogin(userId);
      
      _showSuccess("Welcome to Crystal Social! 🎉");
      
      // Add haptic feedback
      HapticFeedback.mediumImpact();
      
      await Future.delayed(const Duration(milliseconds: 1500));
      widget.onLogin(username);
      
    } catch (e) {
      print('❌ Signup error details: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is AuthException) {
        print('❌ AuthException message: ${e.message}');
        print('❌ AuthException statusCode: ${e.statusCode}');
      }
      
      // Enhanced error handling for different error types
      if (e is AuthException) {
        if (e.message.contains('User already registered')) {
          _showError("This username is already taken. Please try a different one.");
        } else if (e.message.contains('Invalid email')) {
          _showError("Email validation error: ${e.message}");
        } else if (e.message.contains('Password')) {
          _showError("Password requirement not met: ${e.message}");
        } else {
          _showError("Authentication error: ${e.message}");
        }
      } else if (e.toString().contains('unexpected_failure')) {
        _showError("Database configuration error. Please run FINAL_SIGNUP_FIX.sql to remove foreign key constraints.");
      } else if (e.toString().contains('Invalid API key') || e.toString().contains('JWT')) {
        _showError("Authentication service error. Please check your internet connection.");
      } else if (e.toString().contains('relation') || e.toString().contains('table')) {
        _showError("Database table error. Please run FINAL_SIGNUP_FIX.sql first.");
      } else if (e.toString().contains('constraint') || e.toString().contains('unique')) {
        _showError("Username already exists. Please try a different one.");
      } else if (e.toString().contains('connection') || e.toString().contains('network')) {
        _showError("Network error. Please check your internet connection and try again.");
      } else {
        _showError("Signup error: ${e.toString()}");
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    setState(() {
      _error = message;
      _success = null;
    });
    HapticFeedback.selectionClick();
  }

  void _showSuccess(String message) {
    setState(() {
      _success = message;
      _error = null;
    });
    HapticFeedback.lightImpact();
  }

  void _toggleMode() {
    setState(() {
      _isSignup = !_isSignup;
      _error = null;
      _success = null;
    });
    
    // Reset controllers
    _usernameController.clear();
    _passwordController.clear();
    _emailController.clear();
    _confirmPasswordController.clear();
    
    HapticFeedback.selectionClick();
  }

  Widget _buildFloatingParticles() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ParticlePainter(_particles),
      ),
    );
  }

  Widget _buildCrystalLogo() {
    return AnimatedBuilder(
      animation: _crystalController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _crystalRotation.value,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _crystalColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _crystalColors.first.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    int delay = 0,
  }) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 0.5 + delay * 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: Interval(delay * 0.1, 1.0, curve: Curves.easeOut),
          )),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _fadeController,
                curve: Interval(delay * 0.1, 1.0, curve: Curves.easeIn),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon, color: _crystalColors.first),
                  suffixIcon: onToggleVisibility != null
                      ? IconButton(
                          icon: Icon(
                            obscureText ? Icons.visibility : Icons.visibility_off,
                            color: _crystalColors.first,
                          ),
                          onPressed: onToggleVisibility,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _crystalColors.first),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _crystalColors.first.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _crystalColors.first, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  labelStyle: TextStyle(color: _crystalColors.first),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.8),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
          )),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _fadeController,
                curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
              ),
            ),
            child: Container(
              width: double.infinity,
              height: 56,
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _crystalColors.first,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: _crystalColors.first.withOpacity(0.3),
                ),
                onPressed: _loading ? null : (_isSignup ? _signup : _login),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isSignup ? 'Join Crystal Social ✨' : 'Enter Crystal Social 💎',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleButton() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _fadeController,
              curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
            ),
          ),
          child: TextButton(
            onPressed: _toggleMode,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16),
                children: [
                  TextSpan(
                    text: _isSignup 
                        ? 'Already have an account? ' 
                        : "Don't have an account? ",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  TextSpan(
                    text: _isSignup ? 'Sign In' : 'Sign Up',
                    style: TextStyle(
                      color: _crystalColors.first,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRememberMeSwitch() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _fadeController,
              curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
            ),
          ),
          child: Row(
            children: [
              Switch(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() => _rememberMe = value);
                  HapticFeedback.selectionClick();
                },
                activeColor: _crystalColors.first,
              ),
              const SizedBox(width: 8),
              Text(
                'Remember me',
                style: TextStyle(
                  color: _crystalColors.first,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBanner() {
    if (_error == null && _success == null) return const SizedBox.shrink();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _error != null ? Colors.red.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _error != null ? Colors.red.shade300 : Colors.green.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _error != null ? Icons.error : Icons.check_circle,
            color: _error != null ? Colors.red.shade700 : Colors.green.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error ?? _success ?? '',
              style: TextStyle(
                color: _error != null ? Colors.red.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _crystalColors.last.withOpacity(0.1),
              _crystalColors.first.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildFloatingParticles(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Card(
                        elevation: 20,
                        shadowColor: _crystalColors.first.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCrystalLogo(),
                              const SizedBox(height: 24),
                              
                              Text(
                                _isSignup 
                                    ? 'Join Crystal Social' 
                                    : 'Welcome Back!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: _crystalColors.first,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Text(
                                _isSignup 
                                    ? 'Just username and password needed!'
                                    : 'Enter your crystal realm',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 32),
                              
                              _buildMessageBanner(),
                              
                              _buildAnimatedTextField(
                                controller: _usernameController,
                                label: 'Username',
                                icon: Icons.person,
                                delay: 1,
                              ),
                              
                              _buildAnimatedTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock,
                                obscureText: _obscurePassword,
                                onToggleVisibility: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                                delay: _isSignup ? 2 : 2,
                              ),
                              
                              if (_isSignup) ...[
                                _buildAnimatedTextField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirm Password',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscureConfirmPassword,
                                  onToggleVisibility: () {
                                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                  },
                                  delay: 3,
                                ),
                              ],
                              
                              _buildRememberMeSwitch(),
                              
                              _buildActionButton(),
                              
                              _buildToggleButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class Particle {
  double x;
  double y;
  double size;
  Color color;
  double speed;
  double direction;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.direction,
    required this.opacity,
  });

  factory Particle.random() {
    final random = math.Random();
    return Particle(
      x: random.nextDouble() * 400,
      y: random.nextDouble() * 800,
      size: random.nextDouble() * 4 + 1,
      color: Color.lerp(
        const Color(0xFF8A2BE2),
        const Color(0xFFDDA0DD),
        random.nextDouble(),
      )!,
      speed: random.nextDouble() * 2 + 0.5,
      direction: random.nextDouble() * 2 * math.pi,
      opacity: random.nextDouble() * 0.7 + 0.3,
    );
  }

  void update() {
    x += math.cos(direction) * speed;
    y += math.sin(direction) * speed;

    // Wrap around screen
    if (x < 0) x = 400;
    if (x > 400) x = 0;
    if (y < 0) y = 800;
    if (y > 800) y = 0;

    // Subtle direction changes
    direction += (math.Random().nextDouble() - 0.5) * 0.1;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width / 400, particle.y * size.height / 800),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
