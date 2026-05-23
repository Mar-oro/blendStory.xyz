import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/blend_theme.dart';
import '../widgets/hex_background.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  // ── Typed text lines ──────────────────────────────────────────────────────
  static const _lines = [
    ('Stories do not arrive complete. They surface—fragmented, luminous—\nin the margins between sleep and waking.', 38),
    ('blendStory is the intelligence that writes alongside yours.\nnot before. not after. together. in the same ink.', 32),
    ('∴ your co-author awaits.', 48),
  ];

  static const _coWrite = [
    ('YOU',   'she reached for the door —'),
    ('STORY', '— knowing it had been waiting since before the house was built.'),
    ('YOU',   'the hallway smelled of old paper and something alive.'),
    ('STORY', 'the smell of a story breathing in the dark, patient as a pharaoh\'s seal.'),
    ('YOU',   'I did not choose to be here.'),
    ('STORY', 'the manuscript disagrees. your name was written in its margin before your birth.'),
  ];

  String _typed = '';
  int _lineIdx  = 0;
  int _charIdx  = 0;
  bool _done    = false;
  Timer? _timer;

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    Future.delayed(const Duration(milliseconds: 600), _startTyping);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _startTyping() {
    if (!mounted || _lineIdx >= _lines.length) {
      if (mounted) setState(() => _done = true);
      return;
    }
    final (line, speed) = _lines[_lineIdx];
    if (_charIdx < line.length) {
      setState(() { _typed += line[_charIdx]; _charIdx++; });
      _timer = Timer(Duration(milliseconds: speed), _startTyping);
    } else {
      _lineIdx++;
      _charIdx = 0;
      setState(() { _typed += '\n\n'; });
      _timer = Timer(const Duration(milliseconds: 500), _startTyping);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BlendTheme.bg,
      body: HexBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVol(),
                      const SizedBox(height: 32),
                      _buildTypedHero(),
                      const SizedBox(height: 48),
                      _buildAnnotations(),
                      const SizedBox(height: 48),
                      _buildCoWrite(),
                      const SizedBox(height: 52),
                      _buildCTA(context),
                      const SizedBox(height: 48),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: [BlendTheme.gold, BlendTheme.goldE],
                ).createShader(b),
                blendMode: BlendMode.srcIn,
                child: Text('blendStory',
                  style: GoogleFonts.cinzel(
                    fontSize: 20, letterSpacing: 3,
                    fontWeight: FontWeight.w600, color: Colors.white)),
              ),
              Text('the collaborative codex',
                style: GoogleFonts.imFellEnglish(
                  fontSize: 10, color: BlendTheme.dim,
                  fontStyle: FontStyle.italic)),
            ],
          ),
          const Spacer(),
          _EnterButton(
            label: '[ enter ]',
            onTap: () => Navigator.pushNamed(context, '/login'),
          ),
        ],
      ),
    );
  }

  Widget _buildVol() {
    return Text(
      'Vol. I  ·  The Collaborative Codex  ·  MMXXV',
      style: GoogleFonts.jetBrainsMono(
        fontSize: 9, color: BlendTheme.dim, letterSpacing: 2),
    );
  }

  Widget _buildTypedHero() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: BlendTheme.gold.withValues(alpha: _glowAnim.value * 0.04),
              blurRadius: 60, spreadRadius: 10),
          ],
        ),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.imFellEnglish(
              fontSize: 16, color: BlendTheme.parch,
              height: 1.9, letterSpacing: 0.3),
            children: [
              TextSpan(text: _typed),
              if (!_done)
                TextSpan(
                  text: '|',
                  style: TextStyle(
                    color: BlendTheme.gold.withValues(alpha: _glowAnim.value)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnotations() {
    const notes = [
      ('COLLABORATE', 'narrative structure · character arcs · plot turns · thematic consistency across the length of a work'),
      ('ACCELERATE',  'outline to first draft · scene iteration · unblocking · the work moves when you move with it'),
      ('EXPAND',      'alternate endings · branching timelines · voice testing · the story has more rooms than you entered'),
    ];
    return Column(
      children: notes.asMap().entries.map((e) {
        final (label, text) = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('(${e.key + 1})',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9, color: BlendTheme.gold.withValues(alpha: 0.5))),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.imFellEnglish(
                      fontSize: 11, color: BlendTheme.dim, height: 1.7),
                    children: [
                      TextSpan(
                        text: '$label: ',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9, color: BlendTheme.gold,
                          letterSpacing: 1.5)),
                      TextSpan(text: text),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCoWrite() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BlendTheme.faint,
        border: Border.all(color: BlendTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _coWrite.map((pair) {
          final isYou = pair.$1 == 'YOU';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${pair.$1}  ',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      color: isYou
                          ? BlendTheme.gold.withValues(alpha: 0.7)
                          : BlendTheme.verd.withValues(alpha: 0.8),
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: pair.$2,
                    style: GoogleFonts.imFellEnglish(
                      fontSize: 12,
                      color: isYou ? BlendTheme.parch : BlendTheme.bright,
                      fontStyle: isYou ? FontStyle.normal : FontStyle.italic,
                      height: 1.6),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCTA(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: double.infinity,
          child: Text(
            'open the codex',
            textAlign: TextAlign.center,
            style: GoogleFonts.imFellEnglish(
              fontSize: 13, color: BlendTheme.dim,
              fontStyle: FontStyle.italic, letterSpacing: 1),
          ),
        ),
        const SizedBox(height: 14),
        _EnterButton(
          label: '[ enter the manuscript ]',
          onTap: () => Navigator.pushNamed(context, '/login'),
          large: true,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'powered by Lempyrλ · blendStory.xyz',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 8, color: BlendTheme.dim.withValues(alpha: 0.5),
          letterSpacing: 1),
      ),
    );
  }
}

// ── Enter Button ──────────────────────────────────────────────────────────────

class _EnterButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool large;
  const _EnterButton({required this.label, required this.onTap, this.large = false});
  @override State<_EnterButton> createState() => _EnterButtonState();
}

class _EnterButtonState extends State<_EnterButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hover = true),
      onTapUp:   (_) => setState(() => _hover = false),
      onTapCancel: ()  => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: widget.large ? 28 : 14,
          vertical: widget.large ? 12 : 7),
        decoration: BoxDecoration(
          color: _hover ? BlendTheme.gold.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: _hover ? BlendTheme.gold : BlendTheme.gold.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(2),
          boxShadow: _hover ? [
            BoxShadow(color: BlendTheme.gold.withValues(alpha: 0.15), blurRadius: 16),
          ] : [],
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: widget.large ? 12 : 10,
            color: _hover ? BlendTheme.goldE : BlendTheme.gold,
            letterSpacing: 2),
        ),
      ),
    );
  }
}
