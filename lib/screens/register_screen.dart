import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/dinas.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/otp_service.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpService = OTPService();
  final _firestoreService = FirestoreService();
  bool _isSendingOTP = false;
  String? _selectedDinasId;
  List<Dinas> _dinasList = [];
  bool _isLoadingDinas = true;

  // Password strength
  double _passwordStrength = 0.0;

  // Returns strength 0.0 – 1.0
  double _calcStrength(String pw) {
    if (pw.isEmpty) return 0.0;
    int score = 0;
    if (pw.length >= 8) score++;
    if (pw.contains(RegExp(r'[A-Z]'))) score++;
    if (pw.contains(RegExp(r'[0-9]'))) score++;
    if (pw.contains(RegExp(r'[^a-zA-Z0-9]'))) score++;
    // If length < 8 cap at 1
    if (pw.length < 8) return 0.25;
    return score / 4.0;
  }

  // (label, barColor)
  (String, Color) _strengthLabel(double s) {
    if (s <= 0.25) return ('Lemah', const Color(0xFFEF4444));
    if (s <= 0.50) return ('Cukup', const Color(0xFFF59E0B));
    if (s <= 0.75) return ('Kuat', const Color(0xFFF97316));
    return ('Sangat Kuat', const Color(0xFF22C55E));
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {
        _passwordStrength = _calcStrength(_passwordController.text);
      });
    });
    _loadDinas();
  }

  Future<void> _loadDinas() async {
    try {
      final list = await _firestoreService.getDinasList();
      if (mounted) {
        setState(() {
          // Fallback ke seed data kalau Firestore kosong
          _dinasList = list.isNotEmpty ? list : Dinas.seedDinas.map((d) => Dinas(
            id: d['id']!,
            name: d['name']!,
            code: d['code']!,
            description: d['description']!,
            createdAt: DateTime.now(),
          )).toList();
          _isLoadingDinas = false;
        });
      }
    } catch (_) {
      // Jika Firestore gagal, gunakan seed data
      if (mounted) {
        setState(() {
          _dinasList = Dinas.seedDinas.map((d) => Dinas(
            id: d['id']!,
            name: d['name']!,
            code: d['code']!,
            description: d['description']!,
            createdAt: DateTime.now(),
          )).toList();
          _isLoadingDinas = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Dropdown dinas
  Widget _buildDinasDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dinas',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        if (_isLoadingDinas)
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.navyLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.goldMid, width: 0.5),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldMid),
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedDinasId,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Pilih dinas Anda',
              hintStyle: const TextStyle(color: AppColors.textHint),
              prefixIcon: const Icon(Icons.apartment, color: AppColors.goldMid, size: 20),
              filled: true,
              fillColor: AppColors.navyLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.goldMid, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.goldMid, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.goldLight, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            dropdownColor: AppColors.navyCard,
            style: const TextStyle(color: AppColors.textPrimary),
            items: _dinasList.map((d) {
              final accent = DinasTheme.primaryAccent(d.id);
              return DropdownMenuItem<String>(
                value: d.id,
                child: Text(
                  '${d.code} – ${d.name}',
                  style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedDinasId = v),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.goldLight),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Logo & header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.goldLight, AppColors.goldDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.goldMid.withOpacity(0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.navyDark,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Buat Akun',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bergabung dengan PRANATA',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // Form card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.navyCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.goldMid.withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildField('Nama Lengkap', _nameController, Icons.person_outline, 'Anonymous'),
                        const SizedBox(height: 14),
                        _buildField('Email', _emailController, Icons.mail_outline, 'nama@gmail.com',
                            keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 14),
                        _buildField('Username', _usernameController, Icons.alternate_email, 'username'),
                        const SizedBox(height: 14),
                        _buildField('Password', _passwordController, Icons.lock_outline, '••••••••',
                            obscure: _obscurePassword,
                            toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword)),
                        // ── Password Strength Indicator ──
                        if (_passwordController.text.isNotEmpty) ...[  
                          const SizedBox(height: 8),
                          _buildPasswordStrengthIndicator(),
                        ],
                        const SizedBox(height: 14),
                        _buildField('Konfirmasi Password', _confirmPasswordController, Icons.lock_reset, '••••••••',
                            obscure: _obscureConfirmPassword,
                            toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                        const SizedBox(height: 14),
                        _buildDinasDropdown(),
                        const SizedBox(height: 24),

                        // Submit button
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return SizedBox(
                              width: double.infinity,
                              child: DecoratedBox(
                                decoration: AppTheme.goldGradientButton,
                                child: ElevatedButton(
                                  onPressed: (_isSendingOTP || auth.isLoading) ? null : () => _submit(auth),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: (_isSendingOTP || auth.isLoading)
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyDark),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Lanjut',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.navyDark,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward, size: 18, color: AppColors.navyDark),
                                          ],
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun?',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthProvider auth) async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack('Mohon isi semua field', AppColors.error);
      return;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showSnack('Format email tidak valid', AppColors.error);
      return;
    }
    if (_passwordController.text.length < 8) {
      _showSnack('Password minimal 8 karakter', AppColors.error);
      return;
    }
    if (_passwordStrength <= 0.25) {
      _showSnack('Password terlalu lemah. Tambahkan huruf besar, angka, atau simbol.', AppColors.error);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('Password tidak cocok', AppColors.error);
      return;
    }

    setState(() => _isSendingOTP = true);
    try {
      final otpResult = await _otpService.sendOTPEmail(
        _emailController.text.trim(),
        _nameController.text.trim(),
      );
      setState(() => _isSendingOTP = false);

      if (otpResult['success'] && mounted) {
        final isDemoMode = otpResult['demo_mode'] == true;
        final demoOTP = isDemoMode ? otpResult['otp'] as String? : null;

        final verified = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              email: _emailController.text.trim(),
              userName: _nameController.text.trim(),
              demoOTP: demoOTP,
              onVerified: (s) => Navigator.pop(context, s),
            ),
          ),
        );

        if (verified == true && mounted) {
          final success = await auth.register(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            dinasId: _selectedDinasId,
          );
          if (success && mounted) {
            await auth.login(_usernameController.text.trim(), _passwordController.text);
            if (mounted) {
              _showSnack('Akun berhasil dibuat! Selamat datang 🎉', AppColors.success);
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          } else if (mounted && auth.error != null) {
            _showSnack(auth.error!, AppColors.error);
            auth.clearError();
          }
        }
      } else if (mounted) {
        _showSnack(otpResult['message'] ?? 'Gagal mengirim OTP', AppColors.error);
      }
    } catch (e) {
      setState(() => _isSendingOTP = false);
      if (mounted) _showSnack('Error: $e', AppColors.error);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textHint),
            prefixIcon: Icon(icon, color: AppColors.goldMid, size: 20),
            suffixIcon: toggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.goldMid,
                      size: 20,
                    ),
                    onPressed: toggleObscure,
                  )
                : null,
            filled: true,
            fillColor: AppColors.navyLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.goldMid, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.goldMid, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.goldLight, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final (label, color) = _strengthLabel(_passwordStrength);
    final pw = _passwordController.text;

    final tips = <String>[];
    if (pw.length < 8) tips.add('minimal 8 karakter');
    if (!pw.contains(RegExp(r'[A-Z]'))) tips.add('huruf kapital');
    if (!pw.contains(RegExp(r'[0-9]'))) tips.add('angka');
    if (!pw.contains(RegExp(r'[^a-zA-Z0-9]'))) tips.add('simbol (!@#...)');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = _passwordStrength >= (i + 1) / 4;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 5,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: filled ? color : AppColors.navyLight,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            if (tips.isNotEmpty) ...[
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '· Tambahkan: ${tips.join(', ')}',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
