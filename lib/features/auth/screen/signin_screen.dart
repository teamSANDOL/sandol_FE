import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/sandol_brand.dart';
import 'package:handori/common/component/sandol_button.dart';
import 'package:handori/common/component/sandol_field.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/auth/presentation/widget/auth_scaffold.dart';

/// 기존 회원가입 화면. 두 단계 입력값은 이 화면 생명주기 안에서만 보관한다.
class Signinscreen extends StatefulWidget {
  const Signinscreen({super.key, this.initialLanguage = AuthLanguage.ko});
  final AuthLanguage initialLanguage;
  @override
  State<Signinscreen> createState() => _SigninscreenState();
}

class _SigninscreenState extends State<Signinscreen> {
  int _step = 1;
  late AuthLanguage _language = widget.initialLanguage;
  final _id = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _nickname = TextEditingController();
  final _birthday = TextEditingController();
  final _genderText = TextEditingController();
  DateTime? _birthDate;
  String? _gender;

  List<TextEditingController> get _controllers => [
    _id,
    _password,
    _confirmation,
    _email,
    _name,
    _nickname,
    _birthday,
    _genderText,
  ];
  String _text(String ko, String en) => _language.text(ko, en);
  bool get _passwordValid =>
      _password.text.length >= 8 &&
      RegExp(r'[a-zA-Z]').hasMatch(_password.text) &&
      RegExp(r'[0-9]').hasMatch(_password.text);
  bool get _emailValid =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim());
  bool get _stepOneValid =>
      _id.text.trim().isNotEmpty &&
      _passwordValid &&
      _confirmation.text == _password.text &&
      _emailValid &&
      _name.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_update);
    }
  }

  void _update() => setState(() {});
  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step == 2) {
      setState(() => _step = 1);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.login);
    }
  }

  void _next() {
    if (!_stepOneValid) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    FocusScope.of(context).unfocus();
    setState(() => _step = 2);
  }

  Future<void> _pickBirthday() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      locale: Locale(_language.name),
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: _text('생년월일 선택', 'Select date of birth'),
      cancelText: _text('취소', 'Cancel'),
      confirmText: _text('선택', 'Select'),
      builder:
          (context, child) => Theme(data: SandolTheme.light, child: child!),
    );
    if (picked == null || !mounted) return;
    _birthDate = picked;
    _birthday.text =
        '${picked.year}. ${picked.month.toString().padLeft(2, '0')}. ${picked.day.toString().padLeft(2, '0')}.';
  }

  String _genderLabel(String? value) => switch (value) {
    'female' => _text('여성', 'Female'),
    'male' => _text('남성', 'Male'),
    _ => _text('선택 안 함', 'Prefer not to say'),
  };
  Future<void> _pickGender() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: SandolColors.background,
      showDragHandle: true,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(SandolSpacing.md),
                  child: Text(
                    _text('성별(선택)', 'Gender (optional)'),
                    style: SandolTypography.title,
                  ),
                ),
                for (final value in ['female', 'male', 'none'])
                  ListTile(
                    title: Text(
                      _genderLabel(value),
                      style: SandolTypography.body,
                    ),
                    trailing:
                        _gender == value
                            ? const Icon(
                              Icons.check,
                              color: SandolColors.primary,
                            )
                            : null,
                    onTap: () => context.pop(value),
                  ),
              ],
            ),
          ),
    );
    if (picked == null || !mounted) return;
    _gender = picked;
    _genderText.text = _genderLabel(picked);
  }

  void _changeLanguage(AuthLanguage language) {
    setState(() => _language = language);
    if (_gender != null) _genderText.text = _genderLabel(_gender);
  }

  void _submit() {
    if (!_stepOneValid || _nickname.text.trim().isEmpty || _birthDate == null) {
      return;
    }
    FocusScope.of(context).unfocus();
    // 회원가입 API 계약이 아직 없다. 폼 완료를 실제 계정 생성으로 표시하지 않는다.
    showAuthNotice(
      context,
      _text(
        '회원가입은 준비 중이에요. 입력한 정보는 전송되지 않았어요.',
        'Registration is coming soon. Your details have not been sent.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _step == 1,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && _step == 2) _back();
    },
    child: AuthScaffold(
      key: ValueKey(_step),
      top: 74,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            step: _step,
            onBack: _back,
            language: _language,
            onLanguageChanged: _changeLanguage,
          ),
          const SizedBox(height: SandolSpacing.md),
          AuthSectionTitle(
            title: _text('회원가입', 'Sign up'),
            subtitle:
                _step == 1
                    ? _text(
                      '산돌이 식단 서비스를 이용하기 위한 정보를 입력해 주세요',
                      'Enter your details to use Sandol’s meal service',
                    )
                    : _text(
                      '좋아요! 이제 다음으로 넘어갈게요!',
                      'Great! Just a few more details.',
                    ),
          ),
          const SizedBox(height: 20),
          if (_step == 1) ..._firstStep() else ..._secondStep(),
        ],
      ),
    ),
  );

  List<Widget> _firstStep() => [
    AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Column(
        children: [
          SandolField(
            key: const ValueKey('signup-id'),
            label: _text('아이디', 'ID'),
            hint: _text('로그인하기', 'Your login ID'),
            controller: _id,
            autofillHints: const [AutofillHints.newUsername],
          ),
          const SizedBox(height: SandolSpacing.sm),
          SandolField(
            key: const ValueKey('signup-password'),
            label: _text('비밀번호', 'Password'),
            hint: _text('8자 이상, 영문+숫자', '8+ characters, letters + numbers'),
            controller: _password,
            password: true,
            autofillHints: const [AutofillHints.newPassword],
            errorText:
                _password.text.isNotEmpty && !_passwordValid
                    ? _text(
                      '영문과 숫자를 포함해 8자 이상 입력해 주세요.',
                      'Use 8+ characters with letters and numbers.',
                    )
                    : null,
          ),
          const SizedBox(height: SandolSpacing.sm),
          SandolField(
            key: const ValueKey('signup-confirmation'),
            label: _text('비밀번호 확인', 'Confirm password'),
            hint: _text('비밀번호 재입력', 'Re-enter password'),
            controller: _confirmation,
            password: true,
            errorText:
                _confirmation.text.isNotEmpty &&
                        _confirmation.text != _password.text
                    ? _text('비밀번호가 일치하지 않아요.', 'Passwords do not match.')
                    : null,
          ),
          const SizedBox(height: SandolSpacing.sm),
          SandolField(
            key: const ValueKey('signup-email'),
            size: SandolFieldSize.regular,
            label: _text('이메일', 'Email'),
            hint: 'Sandori.gmail.com',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            errorText:
                _email.text.isNotEmpty && !_emailValid
                    ? _text(
                      '올바른 이메일 주소를 입력해 주세요.',
                      'Enter a valid email address.',
                    )
                    : null,
          ),
          const SizedBox(height: SandolSpacing.sm),
          SandolField(
            key: const ValueKey('signup-name'),
            label: _text('성명', 'Full name'),
            hint: _text('홍길동', 'Your full name'),
            controller: _name,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _next(),
          ),
        ],
      ),
    ),
    const SizedBox(height: 19),
    Text(
      _text('산돌이 식단 서비스란?', 'What is Sandol’s meal service?'),
      textAlign: TextAlign.center,
      style: SandolTypography.caption.copyWith(
        color: SandolColors.muted,
        fontWeight: FontWeight.w700,
      ),
    ),
    const SizedBox(height: SandolSpacing.sm),
    Text(
      _text(
        '매주 월요일 아침마다 학교의 식단을 알려줘요,\n내가 좋아하는 식단을 즐겨찾기 할 수 있어요.',
        'Get campus menus every Monday morning\nand save your favorite meals.',
      ),
      textAlign: TextAlign.center,
      style: SandolTypography.caption.copyWith(color: SandolColors.muted),
    ),
    const SizedBox(height: SandolSpacing.xl),
    SandolButton(
      label: _text('다음으로', 'Next'),
      onPressed: _stepOneValid ? _next : null,
    ),
  ];
  List<Widget> _secondStep() => [
    SandolField(
      key: const ValueKey('signup-nickname'),
      size: SandolFieldSize.regular,
      label: _text('닉네임', 'Nickname'),
      hint: _text('사용할 닉네임', 'Your nickname'),
      controller: _nickname,
      textInputAction: TextInputAction.done,
    ),
    const SizedBox(height: SandolSpacing.sm),
    SandolField(
      key: const ValueKey('signup-birthday'),
      size: SandolFieldSize.regular,
      label: _text('생년월일', 'Date of birth'),
      hint: '2000. 01. 01.',
      controller: _birthday,
      selection: true,
      onTap: _pickBirthday,
    ),
    const SizedBox(height: SandolSpacing.sm),
    SandolField(
      key: const ValueKey('signup-gender'),
      size: SandolFieldSize.regular,
      label: _text('성별', 'Gender'),
      hint: _text('성별(선택)', 'Gender (optional)'),
      controller: _genderText,
      selection: true,
      onTap: _pickGender,
    ),
    const SizedBox(height: SandolSpacing.xl),
    const SandolBrand(variant: SandolBrandVariant.mascot),
    const SizedBox(height: 20),
    SandolButton(
      label: _text('회원가입하기', 'Create account'),
      onPressed:
          _nickname.text.trim().isNotEmpty && _birthDate != null
              ? _submit
              : null,
    ),
  ];
}
