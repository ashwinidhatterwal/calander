import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'calendar_pdf_service.dart';

class RatingPromptState {
  const RatingPromptState(
      {required this.installedAt,
      required this.nextPromptAt,
      this.stopped = false});
  final DateTime installedAt, nextPromptAt;

  /// Records an opt-out or store opening, not proof that a rating was submitted.
  final bool stopped;
  bool isDue(DateTime now) => !stopped && !now.isBefore(nextPromptAt);
}

class RatingPromptStore {
  RatingPromptStore(
      {DateTime Function()? clock,
      Future<DateTime?> Function()? installationTime})
      : clock = clock ?? DateTime.now,
        _installationTime = installationTime ?? _androidInstallationTime;
  final DateTime Function() clock;
  final Future<DateTime?> Function() _installationTime;
  static const key = 'rating_prompt_v1';
  static const firstWait = Duration(hours: 24);
  static const retryWait = Duration(days: 28);
  static const channel = MethodChannel('in.hinducalendar/device');

  static Future<DateTime?> _androidInstallationTime() async {
    try {
      final ms = await channel
          .invokeMethod<int>('firstInstallTime')
          .timeout(const Duration(seconds: 2));
      return ms != null && ms > 0
          ? DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true)
          : null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<RatingPromptState> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    RatingPromptState? existing;
    try {
      final raw =
          jsonDecode(prefs.getString(key) ?? '{}') as Map<String, dynamic>;
      final installed = DateTime.parse(raw['installedAt'] as String).toUtc();
      final next = DateTime.parse(raw['nextPromptAt'] as String).toUtc();
      if (!next.isBefore(installed.add(firstWait))) {
        existing = RatingPromptState(
            installedAt: installed,
            nextPromptAt: next,
            stopped: raw['stopped'] == true);
      }
    } catch (_) {/* Missing/corrupt state uses the installation baseline. */}
    final now = clock().toUtc();
    final native = (await _installationTime())?.toUtc();
    final validNative = native != null && !native.isAfter(now);
    final installed = native != null && !native.isAfter(now)
        ? native
        : existing?.installedAt ?? now;
    // A restored backup must not bypass the first day after a reinstall.
    if (existing != null &&
        (!validNative || existing.installedAt.isAtSameMomentAs(installed))) {
      return existing;
    }
    final initial = RatingPromptState(
        installedAt: installed, nextPromptAt: installed.add(firstWait));
    await save(initial);
    return initial;
  }

  Future<void> save(RatingPromptState state) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
        key,
        jsonEncode({
          'installedAt': state.installedAt.toUtc().toIso8601String(),
          'nextPromptAt': state.nextPromptAt.toUtc().toIso8601String(),
          'stopped': state.stopped,
        }));
    if (!saved) throw StateError('Could not save rating preference');
  }

  Future<RatingPromptState> recordShown(RatingPromptState state) async {
    final next = RatingPromptState(
        installedAt: state.installedAt,
        nextPromptAt: clock().toUtc().add(retryWait),
        stopped: state.stopped);
    // Persist before displaying so process death cannot cause repeated prompts.
    await save(next);
    return next;
  }

  Future<void> stop(RatingPromptState state) => save(RatingPromptState(
      installedAt: state.installedAt,
      nextPromptAt: state.nextPromptAt,
      stopped: true));

  static Future<bool> openPlayStore() async {
    for (final uri in [
      Uri.parse(
          'market://details?id=in.hinducalendar.hindu_calendar&showAllReviews=true'),
      Uri.parse(CalendarPdfService.playStoreUrl),
    ]) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (_) {/* Try the browser fallback. */}
    }
    return false;
  }
}
