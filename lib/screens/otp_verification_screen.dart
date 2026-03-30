import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';
import '../services/otp_service.dart';
import '../config/app_theme.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String userName;
  final Function(bool) onVerified;
  final String? demoOTP;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.userName,
    required this.onVerified,
    this.demoOTP,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final OTPService _otpService = OTPService();

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  Timer? _timer;
  int _remainingSeconds = 300;

  @override
  void initState() {
    super.initState();
    _startTimer();
    if (widget.demoOTP != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDemoOTPDialog(widget.demoOTP!);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = 300;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      setState(() => _errorMessage = 'Masukkan 6 digit kode OTP');
      return;
    }
    setState(() { _isVerifying = true; _errorMessage = null; });
    final result = _otpService.verifyOTP(widget.email, _otpController.text);
    setState(() => _isVerifying = false);
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: AppColors.success),
      );
      widget.onVerified(true);
    } else {
      setState(() => _errorMessage = result['message']);
      _otpController.clear();
    }
  }

  Future<void> _resendOTP() async {
    setState(() { _isResending = true; _errorMessage = null; });
    final result = await _otpService.sendOTPEmail(widget.email, widget.userName);
    setState(() => _isResending = false);
    if (result['success']) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP dikirim ulang ke ${widget.email}'), backgroundColor: AppColors.success),
      );
      if (result.containsKey('otp')) _showDemoOTPDialog(result['otp']);
    } else {
      setState(() => _errorMessage = result['message']);
    }
  }

  void _showDemoOTPDialog(String otp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.navyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.goldMid),
        ),
        title: const Text('🔐 Kode OTP', style: TextStyle(color: AppColors.goldLight)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Kode OTP Anda:', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.goldMid),
              ),
              child: Text(
                otp,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: AppColors.goldLight,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Di produksi nyata, kode ini dikirim via email',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textHint, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.goldLight)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.goldLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Verifikasi Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.goldLight, AppColors.goldDark],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.goldMid.withOpacity(0.4), blurRadius: 20),
                  ],
                ),
                child: const Icon(Icons.mail_outline, size: 40, color: AppColors.navyDark),
              ),

              const SizedBox(height: 24),

              const Text(
                'Cek Email Anda',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.goldLight),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                'Kami mengirim kode 6-digit ke',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.email,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.goldLight),
                textAlign: TextAlign.center,
              ),

              // Demo hint
              if (widget.demoOTP != null)
                GestureDetector(
                  onTap: () => _showDemoOTPDialog(widget.demoOTP!),
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.goldMid.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldMid),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.goldMid),
                        SizedBox(width: 8),
                        Text(
                          'Demo Mode: Tap untuk lihat OTP',
                          style: TextStyle(fontSize: 12, color: AppColors.goldLight),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // OTP input
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: AppColors.navyLight,
                  inactiveFillColor: AppColors.navyLight,
                  selectedFillColor: AppColors.navyMid,
                  activeColor: AppColors.goldLight,
                  inactiveColor: AppColors.goldMid,
                  selectedColor: AppColors.goldLight,
                ),
                cursorColor: AppColors.goldLight,
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: true,
                keyboardType: TextInputType.number,
                textStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                onCompleted: (_) => _verifyOTP(),
                onChanged: (_) => setState(() => _errorMessage = null),
              ),

              // Error
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.navyCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _remainingSeconds > 0 ? AppColors.goldMid : AppColors.error,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: _remainingSeconds > 0 ? AppColors.goldMid : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _remainingSeconds > 0 ? 'Berlaku $_formattedTime lagi' : 'OTP Kedaluwarsa',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _remainingSeconds > 0 ? AppColors.goldLight : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Verify button
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: AppTheme.goldGradientButton,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyDark),
                          )
                        : const Text(
                            'Verifikasi',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyDark),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Tidak terima kode?", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  TextButton(
                    onPressed: _isResending ? null : _resendOTP,
                    child: _isResending
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldLight))
                        : const Text('Kirim Ulang', style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
