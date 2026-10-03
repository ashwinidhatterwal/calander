import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/localization.dart';
import '../data/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.language,
    required this.onRefresh,
  });
  final AppLanguage language;
  final Future<void> Function() onRefresh;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic> settings = {};
  bool busy = true;
  L10n get l => L10n(widget.language);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _load() async {
    try {
      final value = await NotificationService.status();
      if (mounted) setState(() => settings = value);
    } catch (_) {
      _message(
        l.pick(
          'सूचना स्थिति नहीं मिली। दोबारा कोशिश करें।',
          'Could not read notification status. Please retry.',
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  int _minute(String key) => (settings[key] as num?)?.toInt() ?? 300;
  String _time(int minute) {
    final hour = minute ~/ 60;
    final suffix = hour < 12 ? l.pick('पु.', 'AM') : l.pick('अप.', 'PM');
    return '${hour % 12 == 0 ? 12 : hour % 12}:${(minute % 60).toString().padLeft(2, '0')} $suffix';
  }

  Future<void> _save(String key, Object value) async {
    setState(() {
      settings[key] = value;
      busy = true;
    });
    try {
      await NotificationService.configure(
        settings['morning'] == true,
        settings['events'] == true,
        settings['sound'] != false,
        morningMinute: _minute('morningMinute'),
        eventsMinute: _minute('eventsMinute'),
      );
      await widget.onRefresh();
    } catch (_) {
      _message(
        l.pick(
          'सूचनाएँ तैयार नहीं हो सकीं। दोबारा कोशिश करें।',
          'Could not prepare reminders. Please retry.',
        ),
      );
    } finally {
      await _load();
    }
  }

  Future<void> _chooseTime(String key) async {
    final minute = _minute(key);
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (time != null && mounted) await _save(key, time.hour * 60 + time.minute);
  }

  Future<void> _open(String method) async {
    try {
      await NotificationService.openSettings(method);
    } catch (_) {
      _message(
        l.pick(
          'फ़ोन सेटिंग नहीं खुली। ऐप की सेटिंग से खोलें।',
          'Could not open phone settings. Open the app settings manually.',
        ),
      );
    }
  }

  Future<void> _test(bool delayed) async {
    setState(() => busy = true);
    try {
      final posted = await NotificationService.test(
        widget.language,
        delayed: delayed,
      );
      _message(
        posted
            ? delayed
                  ? settings['precise'] != true
                        ? l.pick(
                            'परीक्षण तय हो गया। ऐप बंद करें। सटीक समय की अनुमति के बिना Android सूचना देर से दे सकता है।',
                            'Test scheduled. Close the app. Android may delay it without precise reminder access.',
                          )
                        : l.pick(
                            'परीक्षण तय हो गया। ऐप बंद करें; लगभग एक मिनट बाद सूचना देखें।',
                            'Test scheduled. Close the app and check for a notification in about one minute.',
                          )
                  : l.pick(
                      'परीक्षण सूचना भेजी गई। सूचना पैनल देखें।',
                      'Test notification posted. Check your notification panel.',
                    )
            : l.pick(
                'सूचना अनुमति या सूचना चैनल बंद है। नीचे फ़ोन सेटिंग खोलें।',
                'Notification permission or the channel is blocked. Open phone settings below.',
              ),
      );
    } catch (_) {
      _message(
        l.pick(
          'परीक्षण असफल रहा। स्थिति विवरण देखें।',
          'Test failed. Check the status details.',
        ),
      );
    } finally {
      await _load();
    }
  }

  String _result() {
    switch (settings['lastResult']) {
      case 'posted':
        return l.pick(
          'अंतिम सूचना फ़ोन को भेजी गई',
          'Last notification posted to Android',
        );
      case 'permission_blocked':
        return l.pick(
          'सूचना अनुमति बंद है',
          'Notification permission is blocked',
        );
      case 'channel_blocked':
        return l.pick('सूचना चैनल बंद है', 'Notification channel is blocked');
      case 'cache_missing':
        return l.pick(
          'पंचांग तैयार हो रहा है; फिर कोशिश होगी',
          'Preparing Panchang; delivery will retry',
        );
      default:
        return l.pick('सूचना स्थिति विवरण', 'Notification status details');
    }
  }

  Future<void> _details() async {
    await _load();
    if (!mounted) return;
    final report = settings.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.pick('सूचना स्थिति', 'Notification status')),
        content: SingleChildScrollView(child: SelectableText(report)),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: report));
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l.pick('कॉपी करें', 'Copy')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.pick('बंद करें', 'Close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocked =
        settings['permitted'] != true || settings['channelEnabled'] == false;
    return Scaffold(
      appBar: AppBar(title: Text(l.pick('सूचनाएँ', 'Notifications'))),
      body: ListView(
        children: [
          if (busy) const LinearProgressIndicator(minHeight: 2),
          SwitchListTile(
            title: Text(l.pick('दैनिक पंचांग', 'Daily Panchang')),
            subtitle: Text(
              l.pick(
                'तारीख, तिथि, पर्व और आज के कार्यक्रम',
                'Date, tithi, festivals and today’s events',
              ),
            ),
            value: settings['morning'] == true,
            onChanged: busy ? null : (v) => _save('morning', v),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(l.pick('पंचांग का समय', 'Panchang reminder time')),
            trailing: Text(_time(_minute('morningMinute'))),
            onTap: busy ? null : () => _chooseTime('morningMinute'),
          ),
          SwitchListTile(
            title: Text(l.pick('मेरे कार्यक्रम', 'Personal events')),
            subtitle: Text(
              l.pick(
                'कार्यक्रम के दिन याद दिलाएँ',
                'A reminder on the event day',
              ),
            ),
            value: settings['events'] == true,
            onChanged: busy ? null : (v) => _save('events', v),
          ),
          ListTile(
            leading: const Icon(Icons.event_available_outlined),
            title: Text(
              l.pick('कार्यक्रम सूचना का समय', 'Event reminder time'),
            ),
            trailing: Text(_time(_minute('eventsMinute'))),
            onTap: busy ? null : () => _chooseTime('eventsMinute'),
          ),
          SwitchListTile(
            title: Text(l.pick('मधुर ध्वनि', 'Gentle chime')),
            value: settings['sound'] != false,
            onChanged: busy ? null : (v) => _save('sound', v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(
              l.pick('अभी परीक्षण सूचना भेजें', 'Send test notification now'),
            ),
            onTap: busy ? null : () => _test(false),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(l.pick('एक मिनट बाद परीक्षण', 'Test in one minute')),
            subtitle: Text(
              l.pick(
                'परीक्षण तय करके ऐप बंद करें।',
                'Schedule the test, then close the app.',
              ),
            ),
            onTap: busy ? null : () => _test(true),
          ),
          ListTile(
            leading: Icon(
              blocked
                  ? Icons.notifications_off_outlined
                  : Icons.check_circle_outline,
            ),
            title: Text(
              blocked
                  ? l.pick('सूचनाएँ बंद हैं', 'Notifications are blocked')
                  : l.pick('सूचना अनुमति चालू है', 'Notifications are enabled'),
            ),
            subtitle: Text(
              l.pick(
                'फ़ोन की सूचना सेटिंग खोलें',
                'Open phone notification settings',
              ),
            ),
            onTap: () => _open('notificationSettings'),
          ),
          ListTile(
            leading: const Icon(Icons.alarm),
            title: Text(
              l.pick('सटीक समय की अनुमति', 'Precise reminder timing'),
            ),
            subtitle: Text(
              settings['precise'] == true
                  ? l.pick(
                      'चालू है। चुने हुए समय पर सूचना तय है।',
                      'Enabled. Reminders use your selected time.',
                    )
                  : l.pick(
                      'समय पर सूचना के लिए “अलार्म और रिमाइंडर” अनुमति दें। इसके बिना सूचना देर से आ सकती है।',
                      'Allow “Alarms & reminders” for precise timing. Without it, notifications may arrive later.',
                    ),
            ),
            onTap: () => _open('alarmSettings'),
          ),
          if (settings['batteryRestricted'] == true ||
              settings['batteryOptimized'] == true)
            ListTile(
              leading: const Icon(Icons.battery_saver_outlined),
              title: Text(
                l.pick(
                  'बैटरी और पृष्ठभूमि सेटिंग',
                  'Battery and background settings',
                ),
              ),
              subtitle: Text(
                l.pick(
                  'सूचनाएँ फिर भी देर से आएँ तो ऐप की बैटरी सेटिंग में पृष्ठभूमि गतिविधि चालू करें।',
                  'If reminders still arrive late, allow background activity in the app’s battery settings.',
                ),
              ),
              onTap: () => _open('batterySettings'),
            ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(_result()),
            subtitle: Text(
              settings['cacheReady'] == true
                  ? l.pick('आज का पंचांग तैयार है', 'Today’s Panchang is ready')
                  : l.pick(
                      'आज का पंचांग अभी तैयार नहीं है',
                      'Today’s Panchang is not ready yet',
                    ),
            ),
            onTap: busy ? null : _details,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l.pick(
                'समय फ़ोन के समय क्षेत्र के अनुसार है। सामान्य रूप से ऐप बंद होने पर भी सूचनाएँ आती हैं; फ़ोर्स स्टॉप के बाद ऐप फिर खोलें। छूटी हुई सूचना उसी दिन फिर भेजने की कोशिश होती है। सूचनाओं के लिए इंटरनेट या नया GPS स्थान नहीं चाहिए।',
                'Times follow your phone’s time zone. Reminders work when the app is closed normally; reopen after force-stop. Missed reminders retry on the same day. No internet or fresh GPS fix is needed.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
