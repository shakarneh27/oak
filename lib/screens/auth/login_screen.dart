import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/app_user.dart';
import '../../providers/core_providers.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/oak_logo.dart';

/// تسجيل الدخول: فصل المستخدمين حسب الدور (طالب / معلم / ولي أمر) — يعتمد
/// على Supabase Auth بدلاً من حدث `auth_session_init` اليدوي.
class LoginScreen extends ConsumerStatefulWidget {
  /// When true the screen opens on the "حساب جديد" tab (deep link
  /// `/login?mode=signup` from the landing page).
  final bool startInSignUp;

  const LoginScreen({super.key, this.startInSignUp = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _classroomController = TextEditingController();

  late bool _isSignUp = widget.startInSignUp;
  UserRole _role = UserRole.student;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _classroomController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      if (_isSignUp) {
        await auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: _role,
          classroom: _classroomController.text.trim().isEmpty
              ? null
              : _classroomController.text.trim(),
        );
      } else {
        await auth.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      // GoRouter's redirect (driven by authStateProvider) takes it from here.
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'العودة للصفحة الرئيسية',
          onPressed: () => context.go('/'),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: LeafBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: OakLogo(size: 72)),
                        const SizedBox(height: AppSpacing.md),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('تسجيل الدخول'),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('حساب جديد'),
                            ),
                          ],
                          selected: {_isSignUp},
                          onSelectionChanged: (s) =>
                              setState(() => _isSignUp = s.first),
                        ),
                        const SizedBox(height: 16),
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'الاسم الكامل',
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<UserRole>(
                            initialValue: _role,
                            decoration: const InputDecoration(
                              labelText: 'الدور',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: UserRole.student,
                                child: Text('طالب'),
                              ),
                              DropdownMenuItem(
                                value: UserRole.teacher,
                                child: Text('معلم'),
                              ),
                              DropdownMenuItem(
                                value: UserRole.parent,
                                child: Text('ولي أمر'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _role = v ?? UserRole.student),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _classroomController,
                            decoration: const InputDecoration(
                              labelText: 'الصف (اختياري)',
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'بريد إلكتروني غير صالح'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                          ),
                          obscureText: true,
                          validator: (v) => (v == null || v.length < 6)
                              ? '6 أحرف على الأقل'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isSignUp ? 'إنشاء الحساب' : 'دخول'),
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
    );
  }
}
