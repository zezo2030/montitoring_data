import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:data_usage_monitor/widgets/custom_form_text_field.dart';
import 'package:data_usage_monitor/utils/validation_utils.dart';
import 'package:data_usage_monitor/extensions/padding_extensions.dart';
import 'package:data_usage_monitor/cubits/auth/auth_cubit.dart';
import 'package:data_usage_monitor/cubits/auth/auth_state.dart';

class LoginFormWidget extends StatefulWidget {
  final Function() onLogin;
  final Function() onForgotPassword;

  const LoginFormWidget({
    Key? key,
    required this.onLogin,
    required this.onForgotPassword,
  }) : super(key: key);

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          widget.onLogin();
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'حدث خطأ أثناء تسجيل الدخول'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            GlassTextFormField(
              controller: _emailController,
              labelText: 'البريد الإلكتروني',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: ValidationUtils.validateEmail,
            ).paddingSymmetric(vertical: 10, horizontal: 24),
            GlassTextFormField(
              controller: _passwordController,
              labelText: 'كلمة المرور',
              prefixIcon: Icons.lock,
              obscureText: !_isPasswordVisible,
              validator: ValidationUtils.validatePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ).paddingSymmetric(vertical: 10, horizontal: 24),
            _buildForgotPasswordButton(),
            BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isAuthenticating ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: state.isAuthenticating
                      ? _buildLoadingIndicator()
                      : Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                ),
              ).paddingSymmetric(vertical: 20, horizontal: 24);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: 2.0,
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: widget.onForgotPassword,
        child: Text(
          'نسيت كلمة المرور؟',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                blurRadius: 2,
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    ).paddingHorizontal(24);
  }
}
