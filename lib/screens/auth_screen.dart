import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habita/constants/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habita/screens/bottom_menu.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/notification_provider.dart';

enum AuthView {  logIn ,signUp, forgotPassword }
class AuthScreen extends StatelessWidget {
  AuthScreen({super.key});
  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<AuthView> _authView = ValueNotifier<AuthView>(AuthView.logIn);
  final ValueNotifier<bool> _isPasswordVisible = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isConfirmPasswordVisible = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isEmailSent = ValueNotifier<bool>(false);

  Future<void> _submitForm(bool isSignUp, BuildContext context, AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      try {
        if (isSignUp) {
          await authProvider.register(authProvider.emailController.text, authProvider.passwordController.text);
          _authView.value = AuthView.logIn;
        } else {
          await authProvider.logIn(authProvider.emailController.text, authProvider.passwordController.text);
          debugPrint('Login Successful');
          authProvider.clearAll();
          if (context.mounted) {
            await Provider.of<HabitProvider>(context, listen: false).fetchHabits();
            await Provider.of<AuthProvider>(context, listen: false).fetchUserData();
            await Provider.of<NotificationProvider>(context,listen: false).fetchNotifications();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BottomMenu()));
          }
        }
      } catch (error) {
        debugPrint('ERRORRR;$error');
        final errorMessage = authProvider.getReadableMessage(error.toString());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    }
  }

  Future<void> _submitForgotPassword(BuildContext context, AuthProvider authProvider) async {
    try {
      await authProvider.forgotPassword(authProvider.emailController.text.trim());
      _isEmailSent.value = true;
    } catch (error) {
      final errorMessage = authProvider.getReadableMessage(error.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.light,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: authProvider.loadSavedPreferences(),
          builder: (context, snapshot) {

            return SingleChildScrollView(
              child: ValueListenableBuilder<AuthView>(
                valueListenable: _authView,
                builder: (context, view, _) {
                  if (view == AuthView.forgotPassword) {
                    return _buildForgotPasswordView(context);
                  }
                  bool isSignUp = (view == AuthView.signUp);
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(isSignUp, context),
                          const SizedBox(height: 40),
                          if (isSignUp)
                            _buildTextField(
                              label: 'Name',
                              controller: authProvider.nameController,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Name is required';
                                return null;
                              },
                            ),

                          _buildTextField(
                            label: "Email",
                            controller: authProvider.emailController,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Email is required';
                              if (!value.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),

                          _buildTextField(
                            controller: authProvider.passwordController,
                            label: "Password",
                            isPassword: true,
                            visibilityNotifier: _isPasswordVisible,
                            textInputAction: isSignUp ? TextInputAction.next : TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!isSignUp) {
                                _submitForm(isSignUp, context, authProvider);
                              }
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Password is required';
                              if (value.length < 6) return 'Password must be at least 6 character';
                              return null;
                            },
                          ),

                          if (isSignUp)
                            _buildTextField(
                              controller: authProvider.confirmPasswordController,
                              label: "Password Confirmation",
                              isPassword: true,
                              visibilityNotifier: _isConfirmPasswordVisible,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submitForm(isSignUp, context, authProvider),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Please confirm your password';
                                if (authProvider.passwordController.text.trim() != authProvider.confirmPasswordController.text.trim()) {
                                  return 'Password mismatch';
                                }
                                return null;
                              },
                            ),
                          if (!isSignUp) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    ValueListenableBuilder<bool>(
                                      valueListenable: authProvider.rememberMeNotifier,
                                      builder: (context, value, _) => Checkbox(
                                          activeColor: AppColors.blackGrey,
                                          checkColor: AppColors.light,
                                          value: value,
                                          onChanged: (v) => authProvider.rememberMeNotifier.value = v!
                                      ),
                                    ),
                                    Text("Remember me", style: GoogleFonts.nunito()),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => _authView.value = AuthView.forgotPassword,
                                  child: Text("Forgot Password?", style: GoogleFonts.nunito(color: AppColors.orange, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 30),
                          _buildButton(
                            isSignUp ? "Sign Up" : "Log In",
                                () => _submitForm(isSignUp, context, authProvider),
                            context.watch<AuthProvider>().isLoading,
                          ),
                          const SizedBox(height: 40),
                          Center(child: Text(isSignUp ? "Or sign up with:" : "Or log in with:", style: GoogleFonts.nunito(color: const Color(0xFF666666)))),
                          const SizedBox(height: 20),
                          _buildSocialButton(context),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    ValueNotifier<bool>? visibilityNotifier,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.nunito(color: const Color(0xFF666666), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ValueListenableBuilder<bool>(
          valueListenable: visibilityNotifier ?? ValueNotifier(false),
          builder: (context, isVisible, child) {
            return TextFormField(
              controller: controller,
              obscureText: isPassword ? !isVisible : false,
              style: GoogleFonts.nunito(),
              textInputAction: textInputAction ?? TextInputAction.next,
              onFieldSubmitted: onFieldSubmitted,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFEDEDED))),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.orange)),
                errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFEDEDED))),
                focusedErrorBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.orange)),
                suffixIcon: isPassword ? IconButton(
                  icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, size: 18, color: Colors.grey),
                  onPressed: () => visibilityNotifier!.value = !visibilityNotifier.value,
                ) : null,
              ),
              validator: validator,
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onTap, bool isLoading) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(gradient: AppColors.orangeGradient, borderRadius: BorderRadius.circular(8)),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
        ),
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: GoogleFonts.nunito(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildForgotPasswordView(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _formKey.currentState?.reset();
                  _isEmailSent.value = false;
                  _authView.value = AuthView.logIn;
                  authProvider.emailController.clear();
                  authProvider.passwordController.clear();
                },
                icon: const Icon(Icons.arrow_back_ios),
              ),
              const SizedBox(width: 10),
              Text(
                "Forgot Password",
                style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackGrey),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ValueListenableBuilder<bool>(
              valueListenable: _isEmailSent,
              builder: (context, sent, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      sent
                          ? "We have sent password reset instructions to your email."
                          : "Enter your email below, we will send instruction to reset your password",
                      style: GoogleFonts.nunito(color: const Color(0xFF666666)),
                    ),
                    const SizedBox(height: 20),

                    if (!sent) ...[
                      _buildTextField(
                        controller: authProvider.emailController,
                        label: "Email",
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submitForgotPassword(context, authProvider),
                      ),
                      _buildButton(
                        "Submit",
                            () => _submitForgotPassword(context, authProvider),
                        context.watch<AuthProvider>().isLoading,
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.orange, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Can't find it? Please make sure to check your spam folder.",
                                style: GoogleFonts.nunito(color: const Color(0xFF666666), fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: TextButton(
                          onPressed: context.watch<AuthProvider>().isLoading
                              ? null
                              : () async {
                            try {
                              await authProvider.forgotPassword(authProvider.emailController.text.trim());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Reset email resent successfully!")),
                              );
                            } catch (error) {
                              final errorMessage = authProvider.getReadableMessage(error.toString());
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
                            }
                          },
                          child: context.watch<AuthProvider>().isLoading
                              ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2)
                          )
                              : Text(
                            "Resend Email",
                            style: GoogleFonts.nunito(
                                color: AppColors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSignUp, BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(isSignUp ? "Sign Up" : "Log In", style: GoogleFonts.nunito(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.blackGrey)),
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            _authView.value = isSignUp ? AuthView.logIn : AuthView.signUp;
            _formKey.currentState?.reset();
            authProvider.clearAll();
          },
          child: Row(
            children: [
              Text(isSignUp ? "Log In" : "Sign Up", style: GoogleFonts.nunito(color: AppColors.orange, fontWeight: FontWeight.bold)),
              const Icon(Icons.chevron_right, color: AppColors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return InkWell(
      onTap: () async {
        try {
          await authProvider.signInWithGoogle();
          debugPrint('Google Login Successful');
          authProvider.clearAll();
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => BottomMenu()),
            );
          }
        } catch (error) {
          final errorMessage = authProvider.getReadableMessage(error.toString());
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Center(
          child: SvgPicture.asset('assets/icons/google.svg', height: 24, width: 24),
        ),
      ),
    );
  }
}