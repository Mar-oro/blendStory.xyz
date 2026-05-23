import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/blend_theme.dart';
import '../services/auth_service.dart';
import '../services/node_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String _status = '';
  Color _statusColor = BlendTheme.dim;

  late AnimationController _blinkCtrl;
  late Animation<double> _blink;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _blink = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut));
    _checkGateway();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _blinkCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkGateway() async {
    setState(() => _status = '> connecting to sar1a.lempyra.com');
    final ok = await BlendAuthService.instance.healthCheck();
    if (mounted) {
      setState(() {
        _status  = ok ? '> gateway online' : '> gateway unreachable';
        _statusColor = ok ? BlendTheme.ok : BlendTheme.err;
      });
    }
  }

  Future<void> _login() async {
    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() {
      _loading = true;
      _status  = '> connecting to sar1a.lempyra.com';
      _statusColor = BlendTheme.dim;
    });
    try {
      await BlendAuthService.instance.login(
          _userCtrl.text.trim(), _passCtrl.text);
      if (mounted) {
        setState(() {
          _status = '> authorized · exchanging token';
          _statusColor = BlendTheme.dim;
        });
      }
      await NodeStore.instance.load();
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() {
          _status = '> access granted · loading studio...';
          _statusColor = BlendTheme.ok;
        });
      }
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _status  = '> error: ${e.toString().replaceFirst('Exception: ', '')}';
          _statusColor = BlendTheme.err;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BlendTheme.bg2,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTerminal(),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    '← back to blendstory',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, color: BlendTheme.dim,
                      decoration: TextDecoration.underline,
                      decorationColor: BlendTheme.dim),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lempyrλ · blendStory.xyz',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8, color: BlendTheme.dim.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTerminal() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: BlendTheme.bg2,
        border: Border.all(color: BlendTheme.border2),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: BlendTheme.gold.withValues(alpha: 0.05),
            blurRadius: 40, spreadRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: BlendTheme.bg4,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              border: Border(bottom: BorderSide(color: BlendTheme.border2)),
            ),
            child: Row(
              children: [
                // RGB dots
                _dot(const Color(0xFFff5f57)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFffbd2e)),
                const SizedBox(width: 6),
                _dot(const Color(0xFF28c840)),
                const Spacer(),
                Text('blendStory.xyz',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10, color: BlendTheme.body)),
                const Spacer(),
                const SizedBox(width: 54), // balance
              ],
            ),
          ),
          // Auth info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Lempyrλ Auth  ·  sar1a.lempyra.com  ·  TLS 1.3',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8, color: BlendTheme.dim, letterSpacing: 1),
            ),
          ),
          // Form
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TermField(
                  label: 'login:',
                  controller: _userCtrl,
                  autofocus: true,
                ),
                const SizedBox(height: 14),
                _TermField(
                  label: 'pass:',
                  controller: _passCtrl,
                  obscure: true,
                  onSubmit: _loading ? null : _login,
                ),
                const SizedBox(height: 20),
                // Status line
                if (_status.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _status,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9, color: _statusColor),
                          ),
                        ),
                        if (_loading)
                          AnimatedBuilder(
                            animation: _blink,
                            builder: (_, __) => Opacity(
                              opacity: _blink.value,
                              child: Text('_',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9, color: _statusColor)),
                            ),
                          ),
                      ],
                    ),
                  ),
                // Auth button
                SizedBox(
                  width: double.infinity,
                  child: _AuthButton(
                    loading: _loading,
                    onTap: _loading ? null : _login,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
    width: 10, height: 10,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c));
}

class _TermField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback? onSubmit;
  final bool autofocus;
  const _TermField({
    required this.label, required this.controller,
    this.obscure = false, this.onSubmit, this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11, color: BlendTheme.gold, letterSpacing: 1)),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            autofocus: autofocus,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12, color: BlendTheme.bright),
            onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
            cursorColor: BlendTheme.gold,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: InputBorder.none,
              hintText: obscure ? '••••••••' : 'username',
              hintStyle: GoogleFonts.jetBrainsMono(
                fontSize: 11, color: BlendTheme.dim),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthButton extends StatefulWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _AuthButton({required this.loading, required this.onTap});
  @override State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton> {
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _hover && !widget.loading
              ? BlendTheme.gold.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: widget.loading
                ? BlendTheme.dim : (_hover ? BlendTheme.goldE : BlendTheme.gold)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(
          child: widget.loading
              ? SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: BlendTheme.gold.withValues(alpha: 0.6)))
              : Text('[ authenticate ]',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: _hover ? BlendTheme.goldE : BlendTheme.gold,
                    letterSpacing: 2)),
        ),
      ),
    );
  }
}
