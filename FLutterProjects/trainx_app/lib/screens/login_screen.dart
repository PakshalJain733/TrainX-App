import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  // State matching Frontend/src/pages/authentication/login.jsx
  String _authMode = 'password'; // 'password' | 'otp'
  String _step = 'email'; // 'email' | 'otp'
  bool _isLoading = false;
  bool _showPassword = false;
  bool _rememberMe = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Password Login Flow ───────────────────────────────────────────────────
  Future<void> _handlePasswordLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await AuthService.loginStudent(
      _emailController.text,
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Invalid credentials. Please try again.';
      });
    }
  }

  // ── Send Email OTP Flow ───────────────────────────────────────────────────
  Future<void> _handleSendOtp() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your registered college email.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await AuthService.sendOtp(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _step = 'otp';
        _successMessage = 'OTP sent successfully to ${_emailController.text.trim()}';
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to send OTP code.';
      });
    }
  }

  // ── Verify Email OTP Flow ─────────────────────────────────────────────────
  Future<void> _handleVerifyOtp() async {
    final enteredOtp = _otpControllers.map((c) => c.text).join();
    if (enteredOtp.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.verifyOtp(
      _emailController.text.trim(),
      enteredOtp,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Invalid or expired OTP code.';
      });
    }
  }

  void _switchAuthMode(String mode) {
    setState(() {
      _authMode = mode;
      _step = 'email';
      _errorMessage = null;
      _successMessage = null;
      _passwordController.clear();
      for (var c in _otpControllers) {
        c.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDBE6F2), // Exact .login-page background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // ─── 1. Brand Hero Stage (matching Frontend/login.jsx left panel) ─
                  _buildBrandHeroCard(),
                  const SizedBox(height: 18),

                  // ─── 2. Main Login Card (matching Frontend/login.jsx right card) ──
                  _buildLoginCard(),
                  const SizedBox(height: 20),

                  // ─── 3. Footer ────────────────────────────────────────────────────
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Top Brand Hero Stage ─────────────────────────────────────────────────
  Widget _buildBrandHeroCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Exact gradient from Frontend login.css: line 830 (.tx-brand-hero-panel)
        gradient: const LinearGradient(
          colors: [
            Color(0xFF080E1F),
            Color(0xFF0D1A36),
            Color(0xFF0A1628),
            Color(0xFF060D1E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0x3338BDF8), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        children: [
          // Eyebrow badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                '✦',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
              ),
              SizedBox(width: 6),
              Text(
                'YOUR LEARNING JOURNEY',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '✦',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Central Glowing Logo (matches .tx-logo-premium-canvas)
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(5),
            child: ClipOval(
              child: Image.asset(
                'assets/images/Logo.png',
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF4F46E5),
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // TrainX Title
          RichText(
            text: const TextSpan(
              text: 'Train',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(
                  text: 'X',
                  style: TextStyle(
                    color: Color(0xFF38BDF8), // Accent blue X from login.css
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Exact slogan from Frontend/login.jsx line 722
          const Text(
            'Learn • Practice • Assess • Excel',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),

          // 3 Feature Badges from website footer
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildFeaturePill('✦ Interactive Learning'),
              _buildFeaturePill('✦ Smart Assessment'),
              _buildFeaturePill('✦ Track Progress'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── Login Form Card (matching Frontend login card) ──────────────────────
  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter your credentials to access your account',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 18),

            // Segmented Auth Mode Switcher (Password vs Email code)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(
                      mode: 'password',
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      mode: 'otp',
                      label: 'Email code',
                      icon: Icons.mail_outline_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Error & Success Feedback Banners
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Color(0xFF059669), fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ─── Mode 1: Password Login Form ────────────────────────────────
            if (_authMode == 'password') ...[
              _buildFieldLabel(icon: Icons.mail_outline_rounded, label: 'Email address *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: _inputDecoration(hint: 'name@college.edu'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Email is required' : null,
              ),
              const SizedBox(height: 16),

              _buildFieldLabel(icon: Icons.lock_outline_rounded, label: 'Password *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: _inputDecoration(
                  hint: 'Enter your password',
                  suffix: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Password is required' : null,
              ),
              const SizedBox(height: 16),

              // Remember Me & Forgot Password Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) => setState(() => _rememberMe = val ?? true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Remember Me',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please contact your College Administrator to reset password.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sign in button (matching .login-send-otp-btn in login.css)
              _buildPrimaryButton(
                label: _isLoading ? 'Authenticating...' : 'Sign in',
                onPressed: _isLoading ? null : _handlePasswordLogin,
              ),
            ]

            // ─── Mode 2: Email OTP Login Form ───────────────────────────────
            else ...[
              if (_step == 'email') ...[
                _buildFieldLabel(icon: Icons.mail_outline_rounded, label: 'Email address *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                  decoration: _inputDecoration(hint: 'name@college.edu'),
                ),
                const SizedBox(height: 20),
                _buildPrimaryButton(
                  label: _isLoading ? 'Sending OTP...' : 'Send OTP',
                  icon: Icons.send_rounded,
                  onPressed: _isLoading ? null : _handleSendOtp,
                ),
              ] else ...[
                Text(
                  'Enter the 6-digit code sent to ${_emailController.text.trim()}',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),

                // 6-digit OTP code input boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    return SizedBox(
                      width: 44,
                      height: 48,
                      child: TextField(
                        controller: _otpControllers[i],
                        focusNode: _otpFocusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
                          ),
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty && i < 5) {
                            _otpFocusNodes[i + 1].requestFocus();
                          } else if (val.isEmpty && i > 0) {
                            _otpFocusNodes[i - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                _buildPrimaryButton(
                  label: _isLoading ? 'Verifying...' : 'Verify & Login',
                  icon: Icons.verified_user_rounded,
                  onPressed: _isLoading ? null : _handleVerifyOtp,
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => setState(() => _step = 'email'),
                  child: const Text('Change email address', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ─── Helpers & Components ─────────────────────────────────────────────────
  Widget _buildSegmentButton({
    required String mode,
    required String label,
    required IconData icon,
  }) {
    final isActive = _authMode == mode;
    return GestureDetector(
      onTap: () => _switchAuthMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        // Exact button gradient from login.css: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%)
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D2563EB),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "Don't have an account? ",
              style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
            ),
            Text(
              "Contact College Admin",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'TrainX Training Portal  •  v1.0',
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
