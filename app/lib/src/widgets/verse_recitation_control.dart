import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../services/verse_audio_catalog.dart';

class VerseRecitationControl extends StatefulWidget {
  final Verse verse;
  final AppStrings strings;
  final ValueChanged<bool>? onPlaybackChanged;

  const VerseRecitationControl({
    super.key,
    required this.verse,
    required this.strings,
    this.onPlaybackChanged,
  });

  @override
  State<VerseRecitationControl> createState() => _VerseRecitationControlState();
}

class _VerseRecitationControlState extends State<VerseRecitationControl> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;

  bool _loading = false;
  bool _playing = false;
  String? _loadedAssetPath;

  String? get _assetPath => verseAudioAssetFor(widget.verse);

  @override
  void initState() {
    super.initState();
    _playerStateSub = _player.playerStateStream.listen((state) {
      final playing = state.playing;
      if (_playing != playing && mounted) {
        setState(() => _playing = playing);
      } else {
        _playing = playing;
      }
      widget.onPlaybackChanged?.call(playing);
    });
  }

  @override
  void didUpdateWidget(covariant VerseRecitationControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verse.id != widget.verse.id && _playing) {
      unawaited(_stop());
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    _loadedAssetPath = null;
    if (mounted) {
      setState(() => _playing = false);
    }
    widget.onPlaybackChanged?.call(false);
  }

  Future<void> _togglePlayback() async {
    final assetPath = _assetPath;
    if (assetPath == null || _loading) {
      return;
    }

    if (_playing) {
      await _player.pause();
      return;
    }

    try {
      setState(() => _loading = true);
      if (_loadedAssetPath != assetPath) {
        await _player.setAsset(assetPath);
        _loadedAssetPath = assetPath;
      }
      await _player.play();
    } catch (error, stackTrace) {
      debugPrint('[VerseRecitation] $error');
      debugPrintStack(label: '[VerseRecitation]', stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.t('verse_recitation_unavailable'))),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      } else {
        _loading = false;
      }
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_assetPath == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final actionLabel = _playing
        ? widget.strings.t('verse_recitation_pause')
        : widget.strings.t('verse_recitation_play');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          IconButton.filledTonal(
            onPressed: _loading ? null : _togglePlayback,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(widget.strings.t('verse_recitation_title')),
                Text(
                  actionLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (_playing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                widget.strings.t('verse_recitation_follow_along'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
