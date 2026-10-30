import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/localization.dart';
import '../data/discovery_share_service.dart';

class DiscoverySharePreview extends StatefulWidget {
  const DiscoverySharePreview({super.key, required this.data});
  final DiscoveryPosterData data;

  @override
  State<DiscoverySharePreview> createState() => _DiscoverySharePreviewState();
}

class _DiscoverySharePreviewState extends State<DiscoverySharePreview> {
  late Future<Uint8List> _image;
  bool _sharing = false;
  @override
  void initState() {
    super.initState();
    _image = DiscoveryShareService.build(widget.data);
  }

  Future<void> _share(Uint8List bytes) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await DiscoveryShareService.share(bytes, widget.data);
    } on MissingPluginException {
      _failure();
    } on PlatformException {
      _failure();
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _failure() {
    if (!mounted) return;
    final l = L10n(widget.data.language);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.pick('फोटो साझा नहीं हो सकी। कृपया फिर कोशिश करें।',
            'Could not share the image. Please try again.'))));
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(widget.data.language);
    return Scaffold(
      appBar: AppBar(
          title: Text(l.pick('साझा करने से पहले देखें', 'Preview your image'))),
      body: FutureBuilder<Uint8List>(
        future: _image,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(l.pick('फोटो तैयार नहीं हो सकी।',
                          'Could not prepare the image.')),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                          onPressed: () => setState(() {
                                _image =
                                    DiscoveryShareService.build(widget.data);
                              }),
                          icon: const Icon(Icons.refresh),
                          label: Text(l.pick('फिर कोशिश करें', 'Try again'))),
                    ])));
          }
          final bytes = snapshot.data;
          if (bytes == null) {
            return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l.pick(
                  'आपकी फोटो तैयार हो रही है…', 'Preparing your image…')),
            ]));
          }
          return Column(children: [
            Expanded(
                child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Image.memory(bytes,
                  gaplessPlayback: true,
                  semanticLabel: l.pick(
                      'आज के पंचांग और सुविचार की साझा करने योग्य फोटो',
                      'Reading and today’s Panchang, ready to share')),
            )),
            SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _sharing ? null : () => _share(bytes),
                        icon: _sharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.share_outlined),
                        label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child:
                                Text(l.pick('फोटो साझा करें', 'Share image'))),
                      )),
                )),
          ]);
        },
      ),
    );
  }
}
