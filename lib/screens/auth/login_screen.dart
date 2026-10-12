import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Admin Controllers
  final _adminFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isAdminRegisterMode = false;

  // Judge Controller
  final _judgeFormKey = GlobalKey<FormState>();
  final _judgeCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        context.read<AppAuthProvider>().clearError();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _judgeCodeController.dispose();
    super.dispose();
  }

  void _submitAdmin() async {
    if (!_adminFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AppAuthProvider>();
    if (_isAdminRegisterMode) {
      await authProvider.registerAdmin(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      await authProvider.loginAdmin(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
  }

  void _submitJudge() async {
    if (!_judgeFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AppAuthProvider>();
    await authProvider.loginJudge(
      accessCode: _judgeCodeController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Branding / Logo
                  Image.asset(
                    'assets/gulay_angat_logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'GulayAngat ScoreSync',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Digital Event Scoring & Consolidation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Tab selector: Judge vs Admin
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.gavel_rounded, size: 18),
                          text: 'Judge Login',
                        ),
                        Tab(
                          icon: Icon(Icons.admin_panel_settings_rounded, size: 18),
                          text: 'Admin Login',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Banner
                  if (authProvider.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Tab View
                  SizedBox(
                    height: 320,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildJudgeTab(authProvider),
                        _buildAdminTab(authProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------ JUDGE FORM (UNIQUE ID ONLY) ------------------ //
  Widget _buildJudgeTab(AppAuthProvider authProvider) {
    return Form(
      key: _judgeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter your assigned Judge ID to begin evaluating contestants.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _judgeCodeController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 2.0,
            ),
            decoration: const InputDecoration(
              labelText: 'Judge Unique ID',
              hintText: 'e.g. JDG-7K9A',
              prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your unique Judge ID';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: authProvider.isLoading ? null : _submitJudge,
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Access Scorecard'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
          const Spacer(),
          Center(
            child: Text(
              'Judge IDs are generated and provided by the Event Admin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ ADMIN FORM (EMAIL & PASSWORD) ------------------ //
  Widget _buildAdminTab(AppAuthProvider authProvider) {
    return Form(
      key: _adminFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Admin Email',
              hintText: 'admin@event.org',
              prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter admin email';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter password';
              }
              if (_isAdminRegisterMode && val.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: authProvider.isLoading ? null : _submitAdmin,
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isAdminRegisterMode ? 'Create Admin Account' : 'Sign In as Admin'),
                      const SizedBox(width: 8),
                      Icon(_isAdminRegisterMode ? Icons.person_add_rounded : Icons.login_rounded, size: 18),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              setState(() {
                _isAdminRegisterMode = !_isAdminRegisterMode;
              });
              context.read<AppAuthProvider>().clearError();
            },
            child: Text(
              _isAdminRegisterMode
                  ? 'Already have an Admin account? Sign In'
                  : "Don't have an Admin account? Create one here",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
