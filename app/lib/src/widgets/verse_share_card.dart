import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerseShareCard extends StatelessWidget {
  final String ref;
  final int chapter;
  final int verseNumber;
  final String translation;
  final String sanskrit;

  const VerseShareCard({
    super.key,
    required this.ref,
    required this.chapter,
    required this.verseNumber,
    required this.translation,
    required this.sanskrit,
  });

  @override
  Widget build(BuildContext context) {
    final displayText =
        translation.trim().isNotEmpty ? translation.trim() : sanskrit.trim();

    return SizedBox(
      width: 1080,
      height: 1350,
      child: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFF6ECDB),
                  Color(0xFFE8D5B8),
                ],
              ),
            ),
          ),
          Positioned(
            right: 80,
            top: 470,
            child: Text(
              '\u0950',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 280,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF92431A).withValues(alpha: 0.05),
                height: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 48, 72, 40),
            child: Column(
              children: <Widget>[
                Text(
                  'Bhagavad Gita',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 54,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92431A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Chapter $chapter \u2022 Verse $verseNumber',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sourceSans3(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF635647),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: 120,
                  height: 1.5,
                  color: const Color(0xFF92431A).withValues(alpha: 0.4),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: Text(
                    displayText,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sourceSerif4(
                      fontSize: 34,
                      fontWeight: FontWeight.w400,
                      height: 1.7,
                      color: const Color(0xFF201A14),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Gita Companion',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sourceSans3(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF635647).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
