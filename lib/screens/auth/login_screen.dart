import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../providers/core_providers.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/oak_logo.dart';

/// شاشة الدخول وإنشاء الحساب — تدفق من خطوتين على نمط المرجع:
/// تسجيل دخول مباشر، أو اختيار الدور ببطاقات بصرية ثم نموذج تسجيل
/// بمتطلبات قوية (كلمة مرور 8+ بحرف ورقم مع مؤشر قوة، تأكيد كلمة
/// المرور، اسم ثنائي، صف إلزامي للطالب والمعلم، وأفاتار للطالب).
class LoginScreen extends ConsumerStatefulWidget {
  /// When true the screen opens on role selection (deep link
  /// `/login?mode=signup` from the landing page).
  final bool startInSignUp;

  const LoginScreen({super.key, this.startInSignUp = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum _AuthStep { signIn, roleSelect, signUpForm }

const _studentAvatars = ['🦊', '🐰', '🐼', '🦁', '🐸', '🦉', '🐢', '🐿️'];

class _RoleSpec {
  final UserRole role;
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final List<String> features;

  const _RoleSpec({
    required this.role,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.features,
  });
}

const _roles = [
  _RoleSpec(
    role: UserRole.student,
    emoji: '🎒',
    title: 'طالب',
    subtitle: 'ابدأ رحلتك مع السنديانة',
    gradient: [Color(0xFF5A8C3E), Color(0xFF3D6B28)],
    features: ['اختبار تحديد المستوى', 'ألعاب تكيفية', 'شجرة تنمو معك'],
  ),
  _RoleSpec(
    role: UserRole.teacher,
    emoji: '📚',
    title: 'معلم',
    subtitle: 'تابع طلابك وتواصل معهم',
    gradient: [Color(0xFF2471A3), Color(0xFF1A5276)],
    features: ['متابعة تقدم الطلاب', 'رسائل الأهل', 'مكافأة بالنجوم'],
  ),
  _RoleSpec(
    role: UserRole.parent,
    emoji: '👨‍👩‍👦',
    title: 'ولي الأمر',
    subtitle: 'راقب تقدم طفلك يومياً',
    gradient: [Color(0xFFB7770D), Color(0xFF8A5A0A)],
    features: ['تقارير التقدم', 'رسائل المعلم', 'إنجازات طفلك'],
  ),
];

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _classroomController = TextEditingController();

  late _AuthStep _step = widget.startInSignUp
      ? _AuthStep.roleSelect
      : _AuthStep.signIn;
  UserRole _role = UserRole.student;
  String _avatar = _studentAvatars.first;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;
  String _password = '';

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // same-route navigation between /login and /login?mode=signup keeps
    // this State alive — sync the step with the new query parameter.
    if (widget.startInSignUp != oldWidget.startInSignUp) {
      _step = widget.startInSignUp ? _AuthStep.roleSelect : _AuthStep.signIn;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameController.dispose();
    _classroomController.dispose();
    super.dispose();
  }

  // ── password requirement checks ──────────────────────────────────────
  bool get _hasMinLength => _password.length >= 8;
  bool get _hasLetter => _password.contains(RegExp(r'[A-Za-zء-ي]'));
  bool get _hasDigit => _password.contains(RegExp(r'\d'));
  int get _strength =>
      (_hasMinLength ? 1 : 0) +
      (_hasLetter ? 1 : 0) +
      (_hasDigit ? 1 : 0) +
      (_password.length >= 12 ? 1 : 0);

  static final _emailRegex = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$');

  String _friendlyError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials')) {
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      }
      if (message.contains('already registered') ||
          error.code == 'user_already_exists') {
        return 'هذا البريد مسجل مسبقاً — جرّب تسجيل الدخول';
      }
      if (message.contains('rate limit')) {
        return 'محاولات كثيرة — انتظر قليلاً ثم حاول مجدداً';
      }
      if (error.code == 'weak_password') {
        return 'كلمة المرور ضعيفة — استخدم 8 أحرف على الأقل بحرف ورقم';
      }
    }
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('Failed to fetch')) {
      return 'تعذر الاتصال — تحقق من اتصالك بالإنترنت';
    }
    return 'حدث خطأ غير متوقع، حاول مرة أخرى';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ref.read(soundServiceProvider).wrong();
      return;
    }
    ref.read(soundServiceProvider).click();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      if (_step == _AuthStep.signUpForm) {
        final classroom = _classroomController.text.trim();
        await auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: _role,
          classroom: _role == UserRole.student ? classroom : null,
          managedClassrooms: _role == UserRole.teacher ? [classroom] : const [],
          avatar: _role == UserRole.student ? _avatar : null,
        );
      } else {
        await auth.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      // GoRouter's redirect (driven by authStateProvider) takes it from here.
    } catch (error) {
      ref.read(soundServiceProvider).wrong();
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goTo(_AuthStep step) {
    ref.read(soundServiceProvider).click();
    setState(() {
      _step = step;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_step) {
          _AuthStep.signIn => 'تسجيل الدخول',
          _AuthStep.roleSelect => 'اختر دورك',
          _AuthStep.signUpForm => 'حساب جديد',
        }),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'رجوع',
          onPressed: () {
            if (_step == _AuthStep.signUpForm) {
              _goTo(_AuthStep.roleSelect);
            } else if (_step == _AuthStep.roleSelect) {
              _goTo(_AuthStep.signIn);
            } else {
              context.go('/');
            }
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: LeafBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: switch (_step) {
                    _AuthStep.signIn => _buildSignInCard(),
                    _AuthStep.roleSelect => _buildRoleSelect(),
                    _AuthStep.signUpForm => _buildSignUpCard(),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── تسجيل الدخول ─────────────────────────────────────────────────────
  Widget _buildSignInCard() {
    return Card(
      key: const ValueKey('sign-in'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: OakLogo(size: 84)),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'أهلاً بعودتك! 👋',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              Center(
                child: Text(
                  'سجّل دخولك لتكمل رحلتك',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _emailField(),
              const SizedBox(height: 12),
              _passwordField(showStrength: false),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null) _errorBanner(),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('دخول'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => _goTo(_AuthStep.roleSelect),
                child: const Text('ليس لديك حساب؟ أنشئ واحداً الآن'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── اختيار الدور ─────────────────────────────────────────────────────
  Widget _buildRoleSelect() {
    return Column(
      key: const ValueKey('role-select'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'أهلاً بك! 👋',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          'اختر دورك للانضمام إلى عالم السنديانة',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final spec in _roles)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  _role = spec.role;
                  _goTo(_AuthStep.signUpForm);
                },
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: spec.gradient,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            spec.emoji,
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spec.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                spec.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final feature in spec.features)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        feature,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_left, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        TextButton(
          onPressed: () => _goTo(_AuthStep.signIn),
          child: const Text(
            'لدي حساب بالفعل — تسجيل الدخول',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ── نموذج إنشاء الحساب ───────────────────────────────────────────────
  Widget _buildSignUpCard() {
    final spec = _roles.firstWhere((r) => r.role == _role);
    return Card(
      key: const ValueKey('sign-up'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: spec.gradient),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      spec.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حساب ${spec.title} جديد',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          spec.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_role == UserRole.student) ...[
                Text(
                  'اختر شخصيتك',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final emoji in _studentAvatars)
                      GestureDetector(
                        onTap: () {
                          ref.read(soundServiceProvider).click();
                          setState(() => _avatar = emoji);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _avatar == emoji
                                ? OakColors.primary.withValues(alpha: 0.2)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _avatar == emoji
                                  ? OakColors.leafDark
                                  : Colors.grey.shade200,
                              width: _avatar == emoji ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person_outline),
                  helperText: 'الاسم الأول واسم العائلة على الأقل',
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return 'الاسم مطلوب';
                  if (trimmed.length < 3) return 'الاسم قصير جداً';
                  if (trimmed.split(RegExp(r'\s+')).length < 2) {
                    return 'أدخل الاسم الأول واسم العائلة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _emailField(),
              const SizedBox(height: 12),
              _passwordField(showStrength: true),
              const SizedBox(height: 8),
              _passwordRequirements(),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscurePassword,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
                validator: (value) => value != _passwordController.text
                    ? 'كلمتا المرور غير متطابقتين'
                    : null,
              ),
              const SizedBox(height: 12),
              if (_role != UserRole.parent)
                TextFormField(
                  controller: _classroomController,
                  decoration: InputDecoration(
                    labelText: _role == UserRole.student
                        ? 'اسم صفك'
                        : 'الصف الذي تديره',
                    prefixIcon: const Icon(Icons.school_outlined),
                    helperText: _role == UserRole.student
                        ? 'مثال: 4أ — اسأل معلمك عن اسم الصف'
                        : 'طلاب هذا الصف سيظهرون في لوحتك تلقائياً',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'اسم الصف مطلوب'
                      : null,
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9E7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '💡 بعد إنشاء حسابك، سيربط معلم الصف حساب طفلك بحسابك لتصلك التقارير.',
                    style: TextStyle(fontSize: 12, height: 1.6),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null) _errorBanner(),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('إنشاء الحساب 🌱'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── shared fields ────────────────────────────────────────────────────
  Widget _emailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      textDirection: TextDirection.ltr,
      decoration: const InputDecoration(
        labelText: 'البريد الإلكتروني',
        prefixIcon: Icon(Icons.alternate_email),
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) return 'البريد الإلكتروني مطلوب';
        if (!_emailRegex.hasMatch(trimmed)) {
          return 'أدخل بريداً إلكترونياً صحيحاً (مثل name@example.com)';
        }
        return null;
      },
    );
  }

  Widget _passwordField({required bool showStrength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textDirection: TextDirection.ltr,
          onChanged: (value) => setState(() => _password = value),
          decoration: InputDecoration(
            labelText: 'كلمة المرور',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              tooltip: _obscurePassword ? 'إظهار' : 'إخفاء',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) {
            final text = value ?? '';
            if (text.isEmpty) return 'كلمة المرور مطلوبة';
            if (_step == _AuthStep.signUpForm) {
              if (text.length < 8) return '8 أحرف على الأقل';
              if (!text.contains(RegExp(r'[A-Za-zء-ي]')) ||
                  !text.contains(RegExp(r'\d'))) {
                return 'يجب أن تحتوي على حرف ورقم معاً';
              }
            }
            return null;
          },
        ),
        if (showStrength && _password.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Container(
                    height: 5,
                    margin: EdgeInsetsDirectional.only(end: i < 3 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: i < _strength
                          ? switch (_strength) {
                              <= 1 => OakColors.coral,
                              2 => const Color(0xFFEAB308),
                              3 => OakColors.primary,
                              _ => OakColors.leafDark,
                            }
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            switch (_strength) {
              <= 1 => 'ضعيفة',
              2 => 'متوسطة',
              3 => 'جيدة',
              _ => 'ممتازة 💪',
            },
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _passwordRequirements() {
    Widget requirement(bool met, String label) => Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: met ? const Color(0xFF22C55E) : Colors.grey.shade300,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: met ? const Color(0xFF15803D) : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          requirement(_hasMinLength, '8 أحرف على الأقل'),
          requirement(_hasLetter, 'تحتوي على حرف'),
          requirement(_hasDigit, 'تحتوي على رقم'),
        ],
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
