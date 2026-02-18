import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/verse_share_card.dart';

class ShareCardService {
  const ShareCardService._();

  static Future<void> shareVerseCard(
    BuildContext context,
    Verse verse,
  ) async {
    final appState = context.read<AppState>();
    final strings = AppStrings(appState.languageCode);
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(strings.t('preparing_image')),
        duration: const Duration(seconds: 1),
      ),
    );

    final boundaryKey = GlobalKey();
    OverlayEntry? overlayEntry;

    try {
      final overlay = Overlay.of(context, rootOverlay: true);

      final entry = OverlayEntry(
        builder: (_) {
          return Positioned(
            left: -9999,
            top: -9999,
            child: Material(
              type: MaterialType.transparency,
              child: RepaintBoundary(
                key: boundaryKey,
                child: VerseShareCard(
                  ref: verse.ref,
                  chapter: verse.chapter,
                  verseNumber: verse.verseNumber,
                  translation: verse.translation,
                  sanskrit: verse.sanskrit,
                ),
              ),
            ),
          );
        },
      );

      overlay.insert(entry);
      overlayEntry = entry;
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final renderObject = boundaryKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('Share boundary is not ready');
      }

      ui.Image image;
      try {
        image = await renderObject.toImage(pixelRatio: 3.0);
      } catch (_) {
        image = await renderObject.toImage(pixelRatio: 2.0);
      }

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Failed to encode image bytes');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/gita_verse_${verse.chapter}_${verse.verseNumber}.png',
      );
      await file.writeAsBytes(pngBytes, flush: true);

      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: 'Bhagavad Gita ${verse.ref}',
      );
    } catch (error, stackTrace) {
      debugPrint('[ShareCardService] $error');
      debugPrintStack(
        label: '[ShareCardService]',
        stackTrace: stackTrace,
      );
      messenger?.showSnackBar(
        SnackBar(content: Text(strings.t('share_failed'))),
      );
    } finally {
      overlayEntry?.remove();
    }
  }
}
