import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../domain/models.dart';
import '../domain/panchang_engine.dart';
import '../domain/personal_event.dart';

class PersonalEventEditorScreen extends StatefulWidget {
  const PersonalEventEditorScreen({
    super.key,
    required this.language,
    required this.location,
    required this.panchang,
    this.initial,
    this.initialDate,
  });

  final AppLanguage language;
  final GeoLocation location;
  final PanchangEngine panchang;
  final PersonalEvent? initial;
  final DateTime? initialDate;

  @override
  State<PersonalEventEditorScreen> createState() => _PersonalEventEditorScreenState();
}

class _PersonalEventEditorScreenState extends State<PersonalEventEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _note;
  late PersonalEventKind _kind;
  late PersonalEventBasis _basis;
  late DateTime _gregorianDate;
  late bool _repeatYearly;
  late int _hinduMonth;
  late PersonalEventPaksha _paksha;
  late int _tithi;
  late bool _adhik;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final baseDate = widget.initialDate ?? DateTime.now();
    _title = TextEditingController(text: initial?.title ?? '');
    _note = TextEditingController(text: initial?.note ?? '');
    _kind = initial?.kind ?? PersonalEventKind.general;
    _basis = initial?.basis ?? PersonalEventBasis.gregorian;
    _repeatYearly = initial?.repeatYearly ?? true;
    _gregorianDate = initial?.gregorianMonth != null
        ? DateTime(
            initial?.gregorianYear ?? baseDate.year,
            initial!.gregorianMonth!,
            initial.gregorianDay!,
          )
        : DateTime(baseDate.year, baseDate.month, baseDate.day);

    final cell = widget.panchang.monthCell(
      DateTime.utc(baseDate.year, baseDate.month, baseDate.day),
      widget.location,
    );
    _hinduMonth = initial?.hinduMonth ?? cell.month.index;
    _paksha = initial?.hinduPaksha ??
        (cell.pakshaHi.startsWith('शुक्ल')
            ? PersonalEventPaksha.shukla
            : PersonalEventPaksha.krishna);
    _tithi = initial?.hinduTithi ?? cell.tithi.index;
    _adhik = initial?.adhikMonth ?? cell.adhik;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(widget.language);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? l.pick('नया कार्यक्रम', 'New event') : l.pick('कार्यक्रम बदलें', 'Edit event')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            TextFormField(
              controller: _title,
              autofocus: widget.initial == null,
              decoration: InputDecoration(
                labelText: l.pick('नाम', 'Title'),
                hintText: l.pick('जैसे: घर की वार्षिक पूजा', 'e.g. Annual family puja'),
                border: const OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l.pick('नाम लिखें', 'Enter a title')
                  : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<PersonalEventKind>(
              initialValue: _kind,
              decoration: InputDecoration(
                labelText: l.pick('प्रकार', 'Type'),
                border: const OutlineInputBorder(),
              ),
              items: PersonalEventKind.values
                  .map((x) => DropdownMenuItem(value: x, child: Text(_kindName(x, l))))
                  .toList(),
              onChanged: (value) => setState(() => _kind = value ?? _kind),
            ),
            const SizedBox(height: 20),
            Text(
              l.pick('तारीख किस अनुसार?', 'Which calendar should this follow?'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SegmentedButton<PersonalEventBasis>(
              segments: [
                ButtonSegment(
                  value: PersonalEventBasis.gregorian,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(l.pick('सामान्य तारीख', 'Normal date')),
                ),
                ButtonSegment(
                  value: PersonalEventBasis.hinduTithi,
                  icon: const Icon(Icons.brightness_3_outlined),
                  label: Text(l.pick('हिन्दू तिथि', 'Hindu Tithi')),
                ),
              ],
              selected: {_basis},
              onSelectionChanged: (value) => setState(() => _basis = value.first),
            ),
            const SizedBox(height: 16),
            if (_basis == PersonalEventBasis.gregorian) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: Text(l.pick('तारीख', 'Date')),
                  subtitle: Text(_gregorianDateLabel(l)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickGregorianDate,
                ),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(l.pick('हर वर्ष इसी तारीख पर', 'Repeat every year on this date')),
                value: _repeatYearly,
                onChanged: (value) => setState(() => _repeatYearly = value),
              ),
            ] else ...[
              DropdownButtonFormField<int>(
                initialValue: _hinduMonth,
                decoration: InputDecoration(
                  labelText: l.pick('हिन्दू मास', 'Hindu month'),
                  border: const OutlineInputBorder(),
                ),
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(widget.language == AppLanguage.hi ? monthHi[i] : monthEn[i]),
                  ),
                ),
                onChanged: (value) => setState(() => _hinduMonth = value ?? _hinduMonth),
              ),
              const SizedBox(height: 14),
              SegmentedButton<PersonalEventPaksha>(
                segments: [
                  ButtonSegment(value: PersonalEventPaksha.shukla, label: Text(l.pick('शुक्ल पक्ष', 'Shukla Paksha'))),
                  ButtonSegment(value: PersonalEventPaksha.krishna, label: Text(l.pick('कृष्ण पक्ष', 'Krishna Paksha'))),
                ],
                selected: {_paksha},
                onSelectionChanged: (value) => setState(() => _paksha = value.first),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _tithi,
                decoration: InputDecoration(
                  labelText: l.tithi,
                  border: const OutlineInputBorder(),
                ),
                items: List.generate(15, (i) {
                  String label;
                  if (i == 14) {
                    label = _paksha == PersonalEventPaksha.shukla
                        ? l.pick('पूर्णिमा', 'Purnima')
                        : l.pick('अमावस्या', 'Amavasya');
                  } else {
                    label = widget.language == AppLanguage.hi ? personalTithiHi[i] : personalTithiEn[i];
                  }
                  return DropdownMenuItem(value: i + 1, child: Text(label));
                }),
                onChanged: (value) => setState(() => _tithi = value ?? _tithi),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(l.pick('अधिक मास की तिथि', 'Date belongs to Adhik Maas')),
                subtitle: Text(l.pick(
                  'सिर्फ तब चुनें जब कार्यक्रम विशेष रूप से अधिक मास में हो।',
                  'Use only when this event specifically belongs to an Adhik month.',
                )),
                value: _adhik,
                onChanged: (value) => setState(() => _adhik = value),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  l.pick(
                    'यह कार्यक्रम हर वर्ष चुने हुए मास, पक्ष और तिथि के अनुसार दिखाई देगा।',
                    'This event will follow the selected Hindu month, Paksha and Tithi every year.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l.pick('नोट (वैकल्पिक)', 'Note (optional)'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check),
          label: Text(l.pick('सहेजें', 'Save')),
        ),
      ),
    );
  }

  Future<void> _pickGregorianDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _gregorianDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: L10n(widget.language).pick('तारीख चुनें', 'Choose date'),
    );
    if (value != null) setState(() => _gregorianDate = value);
  }

  String _gregorianDateLabel(L10n l) {
    final month = widget.language == AppLanguage.hi
        ? monthNamesHi[_gregorianDate.month - 1]
        : monthNamesEn[_gregorianDate.month - 1];
    return '${_gregorianDate.day} $month ${_gregorianDate.year}';
  }

  String _kindName(PersonalEventKind kind, L10n l) => switch (kind) {
        PersonalEventKind.general => l.pick('सामान्य', 'General'),
        PersonalEventKind.birthday => l.pick('जन्मदिन', 'Birthday'),
        PersonalEventKind.anniversary => l.pick('वर्षगाँठ', 'Anniversary'),
        PersonalEventKind.puja => l.pick('पूजा', 'Puja'),
        PersonalEventKind.vrat => l.pick('व्रत', 'Vrat'),
        PersonalEventKind.family => l.pick('परिवार', 'Family'),
      };

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final initial = widget.initial;
    final event = PersonalEvent(
      id: initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      note: _note.text.trim(),
      kind: _kind,
      basis: _basis,
      repeatYearly: _basis == PersonalEventBasis.hinduTithi ? true : _repeatYearly,
      gregorianYear: _basis == PersonalEventBasis.gregorian ? _gregorianDate.year : null,
      gregorianMonth: _basis == PersonalEventBasis.gregorian ? _gregorianDate.month : null,
      gregorianDay: _basis == PersonalEventBasis.gregorian ? _gregorianDate.day : null,
      hinduMonth: _basis == PersonalEventBasis.hinduTithi ? _hinduMonth : null,
      hinduPaksha: _basis == PersonalEventBasis.hinduTithi ? _paksha : null,
      hinduTithi: _basis == PersonalEventBasis.hinduTithi ? _tithi : null,
      adhikMonth: _basis == PersonalEventBasis.hinduTithi && _adhik,
    );
    Navigator.pop(context, event);
  }
}
