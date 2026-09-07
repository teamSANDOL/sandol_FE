import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 조직도 연락처(전화 / 링크 / 이메일) 공용 액션.
///
/// - 탭: 네이티브 앱으로 넘김 (전화 다이얼러 / 브라우저 / 메일 앱)
/// - 길게 누름: 클립보드 복사 + 햅틱 + 스낵바
class ContactActions {
  ContactActions._();

  /// `03180411092` → `031-8041-1092`. 형식이 다르면 원문 그대로 반환.
  static String formatPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length == 11) {
      return '${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7)}';
    }
    if (d.length == 10) {
      return d.startsWith('02')
          ? '${d.substring(0, 2)}-${d.substring(2, 6)}-${d.substring(6)}'
          : '${d.substring(0, 3)}-${d.substring(3, 6)}-${d.substring(6)}';
    }
    if (d.length == 9 && d.startsWith('02')) {
      return '${d.substring(0, 2)}-${d.substring(2, 5)}-${d.substring(5)}';
    }
    return raw;
  }

  static Future<void> copy(
    BuildContext context,
    String text, {
    String label = '내용',
  }) async {
    HapticFeedback.mediumImpact();
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    _toast(context, '$label을(를) 복사했습니다');
  }

  /// 전화 앱(다이얼러)을 연다. 실제 발신은 사용자가 다이얼러에서 확인 후 진행하므로
  /// CALL_PHONE 권한이 필요 없다. 다이얼러가 없는 기기(태블릿 등)는 복사로 대체.
  static Future<void> dial(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final ok = await _launch(Uri(scheme: 'tel', path: digits));
    if (!ok && context.mounted) {
      await Clipboard.setData(ClipboardData(text: digits));
      if (context.mounted) {
        _toast(context, '전화 앱을 열 수 없어 번호를 복사했습니다');
      }
    }
  }

  static Future<void> mail(BuildContext context, String email) async {
    final ok = await _launch(Uri(scheme: 'mailto', path: email));
    if (!ok && context.mounted) {
      await Clipboard.setData(ClipboardData(text: email));
      if (context.mounted) {
        _toast(context, '메일 앱을 열 수 없어 주소를 복사했습니다');
      }
    }
  }

  static Future<void> openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    final ok = uri != null &&
        await _launch(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _toast(context, '링크를 열 수 없습니다');
    }
  }

  static Future<bool> _launch(
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    try {
      return await launchUrl(uri, mode: mode);
    } on PlatformException {
      return false;
    }
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
