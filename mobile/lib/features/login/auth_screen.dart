import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/components/glass_components.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login form
  final _loginFormKey = GlobalKey<FormState>();
  final _loginMobileController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Signup form
  final _signupFormKey = GlobalKey<FormState>();
  final _signupNameController = TextEditingController();
  final _signupMobileController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginMobileController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupMobileController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  String _getDeviceName() {
    if (kIsWeb) return 'Web Browser';
    return 'Mobile Device';
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final deviceName = _getDeviceName();

    final success = await authProvider.login(
      _loginMobileController.text.trim(),
      _loginPasswordController.text,
      deviceName: deviceName,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;

    if (_signupPasswordController.text !=
        _signupConfirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final deviceName = _getDeviceName();

    final success = await authProvider.signup(
      fullName: _signupNameController.text.trim(),
      mobileNumber: _signupMobileController.text.trim(),
      password: _signupPasswordController.text,
      deviceName: deviceName,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Signup failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E003E),
                  Colors.black,
                  Color(0xFF1A1A00),
                ],
              ),
            ),
          ),

          // Background Circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.2),
                    blurRadius: 80,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Logo/Title
                // Logo/Title
                Image.asset(
                  'assets/AKHpng.png',
                  height: 120,
                  width: 120,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Welcome To AKH',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Tab Bar
                GlassContainer(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginTab(),
                      _buildSignupTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTab() {
    final isLoading =
        context.watch<AuthProvider>().status == AuthStatus.loading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: GlassContainer(
        child: Form(
          key: _loginFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              GlassTextField(
                controller: _loginMobileController,
                label: 'Mobile Number',
                hint: '+1234567890',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              GlassTextField(
                controller: _loginPasswordController,
                label: 'Password',
                prefixIcon: Icons.lock,
                obscureText: _obscureLoginPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureLoginPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(
                      () => _obscureLoginPassword = !_obscureLoginPassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              GlassButton(
                text: 'Login',
                icon: Icons.login,
                isLoading: isLoading,
                onPressed: _handleLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignupTab() {
    final isLoading =
        context.watch<AuthProvider>().status == AuthStatus.loading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: GlassContainer(
        child: Form(
          key: _signupFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              GlassTextField(
                controller: _signupNameController,
                label: 'Full Name',
                hint: 'John Doe',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              GlassTextField(
                controller: _signupMobileController,
                label: 'Mobile Number',
                hint: '+1234567890',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              GlassTextField(
                controller: _signupPasswordController,
                label: 'Password',
                prefixIcon: Icons.lock,
                obscureText: _obscureSignupPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSignupPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(
                      () => _obscureSignupPassword = !_obscureSignupPassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              GlassTextField(
                controller: _signupConfirmPasswordController,
                label: 'Confirm Password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              GlassButton(
                text: 'Create Account',
                icon: Icons.person_add,
                isLoading: isLoading,
                onPressed: _handleSignup,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'By signing up, you will be registered as an Employee.\nContact Admin to be assigned to a team.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
