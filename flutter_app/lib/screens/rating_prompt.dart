import 'dart:async';
import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../data/rating_prompt_store.dart';

enum RatingChoice { rate, later, never }

class RatingPromptDialog extends StatelessWidget {
  const RatingPromptDialog({super.key, required this.language});
  final AppLanguage language;
  @override
  Widget build(BuildContext context) {
    final l = L10n(language);
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16)),
                        child: Icon(Icons.rate_review_outlined,
                            color: theme.colorScheme.primary)),
                    const Spacer(),
                    IconButton(
                        tooltip: l.pick('बंद करें', 'Close'),
                        onPressed: () =>
                            Navigator.pop(context, RatingChoice.later),
                        icon: const Icon(Icons.close)),
                  ]),
                  const SizedBox(height: 12),
                  Text(l.pick('अपना अनुभव साझा करें', 'Share your experience'),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text(
                      l.pick(
                          'हिन्दू कैलेंडर के साथ अपना अनुभव Play Store पर बताएँ। आपकी रेटिंग दूसरों को ऐप के बारे में जानने में मदद करेगी।',
                          'Share your experience with Hindu Calendar on Google Play. Your rating helps others learn about the app.'),
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.55)),
                  const SizedBox(height: 22),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                          onPressed: () =>
                              Navigator.pop(context, RatingChoice.rate),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(l.pick('Play Store पर रेटिंग दें',
                                  'Rate on Google Play'))))),
                  const SizedBox(height: 6),
                  SizedBox(
                      width: double.infinity,
                      child: TextButton(
                          onPressed: () =>
                              Navigator.pop(context, RatingChoice.later),
                          child: Text(l.pick('अभी नहीं', 'Not now')))),
                  Center(
                      child: TextButton(
                          onPressed: () =>
                              Navigator.pop(context, RatingChoice.never),
                          child: Text(l.pick('फिर न पूछें', 'Don’t ask again'),
                              style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant)))),
                ]),
          ))),
    );
  }
}

/// Only the visible home route can offer a rating. Background tasks, editors,
/// location prompts and sharing previews never receive a competing popup.
class RatingPromptGate extends StatefulWidget {
  const RatingPromptGate(
      {super.key,
      required this.language,
      required this.child,
      this.store,
      this.initialDelay = const Duration(seconds: 8),
      this.openStore});
  final AppLanguage language;
  final Widget child;
  final RatingPromptStore? store;
  final Duration initialDelay;
  final Future<bool> Function()? openStore;
  @override
  State<RatingPromptGate> createState() => _RatingPromptGateState();
}

class _RatingPromptGateState extends State<RatingPromptGate>
    with WidgetsBindingObserver {
  late final RatingPromptStore _store = widget.store ?? RatingPromptStore();
  RatingPromptState? _state;
  Timer? _timer;
  DateTime? _lastInteraction;
  bool _foreground = true, _checking = false, _promptedThisSession = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _schedule(widget.initialDelay);
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    if (!mounted || !_foreground || _promptedThisSession) return;
    _timer = Timer(delay, _check);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _promptedThisSession = false;
      _state = null; // Re-read a manual rating/opt-out made on another screen.
      _schedule(widget.initialDelay);
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _check() async {
    if (_checking || !mounted || !_foreground || _promptedThisSession) return;
    _checking = true;
    try {
      final state = _state ??= await _store.initialize();
      if (!mounted || !_foreground || state.stopped) return;
      final now = _store.clock().toUtc();
      if (!state.isDue(now)) {
        _schedule(state.nextPromptAt.difference(now));
        return;
      }
      final interaction = _lastInteraction;
      if (interaction != null) {
        final quietFor = now.difference(interaction.toUtc());
        if (quietFor < widget.initialDelay) {
          _schedule(widget.initialDelay - quietFor);
          return;
        }
      }
      if (ModalRoute.of(context)?.isCurrent != true ||
          Navigator.of(context).userGestureInProgress) {
        _schedule(const Duration(seconds: 30));
        return;
      }
      final shownState = await _store.recordShown(state);
      _state = shownState;
      if (!mounted ||
          !_foreground ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      _promptedThisSession = true;
      final choice = await showDialog<RatingChoice>(
          context: context,
          builder: (_) => RatingPromptDialog(language: widget.language));
      if (choice == RatingChoice.never) {
        await _store.stop(shownState);
      } else if (choice == RatingChoice.rate) {
        final opened =
            await (widget.openStore ?? RatingPromptStore.openPlayStore)();
        if (opened) {
          await _store.stop(shownState);
        } else if (mounted) {
          final l = L10n(widget.language);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l.pick(
                  'Play Store नहीं खुल सका। ऐप के बारे में वाले पृष्ठ से फिर कोशिश करें।',
                  'Could not open Google Play. You can try again from About.'))));
        }
      }
    } catch (_) {
      // Optional review UI and local preference failures never interrupt use.
    } finally {
      _checking = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _lastInteraction = _store.clock(),
        onPointerMove: (_) => _lastInteraction = _store.clock(),
        child: widget.child,
      );
}
