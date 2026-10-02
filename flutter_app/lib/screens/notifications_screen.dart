import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../data/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen(
      {super.key, required this.language, required this.onRefresh});
  final AppLanguage language;
  final Future<void> Function() onRefresh;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic> settings = {};
  bool busy = true;
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

  Future<void> _load() async {
    final value = await NotificationService.status();
    if (mounted) {
      setState(() {
        settings = value;
        busy = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _change(String key, bool value) async {
    setState(() {
      settings[key] = value;
      busy = true;
    });
    try {
      await NotificationService.configure(settings['morning'] == true,
          settings['events'] == true, settings['sound'] != false);
      await widget.onRefresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L10n(widget.language).pick(
                'सूचनाएँ तैयार नहीं हो सकीं। दोबारा कोशिश करें।',
                'Could not prepare reminders. Please retry.'))));
      }
    } finally {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(widget.language);
    return Scaffold(
        appBar: AppBar(title: Text(l.pick('सूचनाएँ', 'Notifications'))),
        body: ListView(children: [
          if (busy) const LinearProgressIndicator(minHeight: 2),
          SwitchListTile(
              title: Text(l.pick('सुबह का पंचांग', 'Morning Panchang')),
              subtitle: Text(l.pick('हर सुबह लगभग 5 बजे: तारीख, तिथि और पर्व',
                  'Every morning around 5 AM: date, tithi and festivals')),
              value: settings['morning'] == true,
              onChanged: busy ? null : (v) => _change('morning', v)),
          SwitchListTile(
              title: Text(l.pick('मेरे कार्यक्रम', 'Personal events')),
              subtitle: Text(l.pick(
                  'सहेजने पर पुष्टि और कार्यक्रम के दिन सुबह लगभग 5 बजे याद दिलाएँ',
                  'Confirmation when saved and a reminder around 5 AM on the event day')),
              value: settings['events'] == true,
              onChanged: busy ? null : (v) => _change('events', v)),
          SwitchListTile(
              title: Text(l.pick('मधुर ध्वनि', 'Gentle chime')),
              value: settings['sound'] != false,
              onChanged: busy ? null : (v) => _change('sound', v)),
          if (settings['permitted'] != true &&
              (settings['morning'] == true || settings['events'] == true))
            ListTile(
                leading: const Icon(Icons.notifications_off_outlined),
                title: Text(l.pick(
                    'सूचना अनुमति बंद है', 'Notification permission is off')),
                subtitle: Text(l.pick(
                    'फ़ोन की ऐप सेटिंग में सूचनाएँ चालू करें।',
                    'Enable notifications in the phone’s app settings.')),
                onTap: () => _change('morning', settings['morning'] == true)),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.pick(
                  'केवल सामान्य सूचना अनुमति चाहिए। Android बैटरी बचाने के लिए 5 बजे की सूचना देर से दे सकता है। ऐप सामान्य रूप से बंद होने पर भी सूचनाएँ चलती हैं; फ़ोर्स स्टॉप के बाद ऐप फिर खोलें। समय फ़ोन के समय क्षेत्र के अनुसार है। पंचांग सहेजे हुए स्थान और IST प्रोफ़ाइल से बनता है। सूचनाओं के लिए इंटरनेट या नया GPS स्थान नहीं चाहिए।',
                  'Only ordinary notification permission is needed. Android may delay the 5 AM reminder to save battery. Reminders work when the app is closed normally; reopen after force-stop. 5 AM follows your phone’s time zone. Panchang uses your saved location and the IST profile. Reminders need neither internet nor a fresh GPS fix.'))),
        ]));
  }
}
