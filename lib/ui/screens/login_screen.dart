import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../widgets/liquid_glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool isLogin = true;
  bool loading = false;

  void _submit() async {
    if (_email.text.isEmpty || _password.text.isEmpty) return;
    setState(() => loading = true);
    try {
      if (isLogin) {
        await AuthService().login(_email.text, _password.text);
      } else {
        await AuthService().signUp(_email.text, _password.text);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedLiquidBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 120),
                Hero(
                  tag: 'logo',
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 40)],
                    ),
                    child: const Icon(Icons.nights_stay_rounded, size: 80, color: Colors.white),
                  ),
                ).animate().scale(duration: 1.seconds, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  "Sleep Love",
                  style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -1, color: Colors.white),
                ).animate().fadeIn(delay: 500.ms),
                Text(
                  "Escape into deep relaxation",
                  style: GoogleFonts.outfit(fontSize: 16, color: Colors.white38),
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 60),
                
                LiquidGlassCard(
                  padding: const EdgeInsets.all(32),
                  borderRadius: 40,
                  child: Column(
                    children: [
                      Text(
                        isLogin ? "Welcome Back" : "Join the Calm",
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 32),
                      _buildTextField(_email, "Email", Icons.email_outlined),
                      const SizedBox(height: 20),
                      _buildTextField(_password, "Password", Icons.lock_outline_rounded, isObscure: true),
                      const SizedBox(height: 32),
                      if (loading)
                        const CircularProgressIndicator(color: AppColors.primary)
                      else
                        GestureDetector(
                          onTap: _submit,
                          child: Container(
                            height: 60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: AppColors.purpleGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20)],
                            ),
                            child: Center(
                              child: Text(
                                isLogin ? "Sign In" : "Get Started",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin ? "Don't have an account? Sign Up" : "Already have an account? Sign In",
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => AuthService().signInAnonymously(),
                  child: const Text("Continue as Guest", style: TextStyle(color: Colors.white24)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isObscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
