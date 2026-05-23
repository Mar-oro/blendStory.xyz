import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/blend_theme.dart';
import '../models/story_node.dart';

class NodeModalScreen extends StatefulWidget {
  final StoryNode node;
  final bool isNew;
  const NodeModalScreen({super.key, required this.node, required this.isNew});
  @override State<NodeModalScreen> createState() => _NodeModalScreenState();
}

class _NodeModalScreenState extends State<NodeModalScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _promptCtrl;
  String _genOutput = '';
  bool _generating  = false;
  Timer? _genTimer;
  int _mockIdx = 0;

  @override
  void initState() {
    super.initState();
    _titleCtrl   = TextEditingController(text: widget.node.title);
    _contentCtrl = TextEditingController(text: widget.node.content);
    _promptCtrl  = TextEditingController(text: widget.node.prompt);
    _genOutput   = widget.node.generatedOutput;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _promptCtrl.dispose();
    _genTimer?.cancel();
    super.dispose();
  }

  void _generate() {
    if (_generating) return;
    setState(() { _generating = true; _genOutput = ''; });
    final type = widget.node.type;

    if (type == NodeType.text) {
      final text = kMockTextOutputs[_mockIdx % kMockTextOutputs.length];
      _mockIdx++;
      int i = 0;
      _genTimer = Timer.periodic(const Duration(milliseconds: 18), (_) {
        if (!mounted) { _genTimer?.cancel(); return; }
        if (i < text.length) {
          setState(() => _genOutput += text[i++]);
        } else {
          _genTimer?.cancel();
          setState(() => _generating = false);
        }
      });
    } else if (type == NodeType.audio) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _genOutput  = kWaveform;
            _generating = false;
          });
        }
      });
    } else if (type == NodeType.image) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _genOutput  = '[image generated — visual canvas]';
            _generating = false;
          });
        }
      });
    }
  }

  StoryNode get _built => StoryNode(
    id: widget.node.id,
    type: widget.node.type,
    title: _titleCtrl.text.trim().isEmpty ? widget.node.title : _titleCtrl.text.trim(),
    content: _contentCtrl.text,
    prompt: _promptCtrl.text,
    generatedOutput: _genOutput,
    created: widget.node.created,
  );

  @override
  Widget build(BuildContext context) {
    final color = BlendTheme.nodeColor(widget.node.type.key);
    final title = widget.isNew
        ? 'new ${widget.node.type.label.toLowerCase()} node'
        : 'edit #${widget.node.id} — ${widget.node.title}';

    return Scaffold(
      backgroundColor: BlendTheme.bg2,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: BlendTheme.bg4,
              child: Row(
                children: [
                  Text('${widget.node.type.icon}  ',
                    style: TextStyle(fontSize: 16, color: color)),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: BlendTheme.body, letterSpacing: 1),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('[cancel]',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9, color: BlendTheme.dim)),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('TITLE'),
                    const SizedBox(height: 6),
                    _field(_titleCtrl, maxLines: 1, hint: 'node title'),
                    const SizedBox(height: 20),
                    _label('CONTENT'),
                    const SizedBox(height: 6),
                    _field(_contentCtrl, maxLines: 8, hint: 'write something...'),
                    if (widget.node.type.canGenerate) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _label('GENERATE'),
                          const SizedBox(width: 6),
                          Text('Lempyrλ',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 7, color: BlendTheme.gold.withValues(alpha: 0.5))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _field(_promptCtrl, maxLines: 2, hint: 'describe what to generate...')),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _generate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: color.withValues(alpha: 0.5)),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: _generating
                                  ? SizedBox(width: 14, height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: color.withValues(alpha: 0.7)))
                                  : Text('▶ RUN',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9, color: color, letterSpacing: 1)),
                            ),
                          ),
                        ],
                      ),
                      if (_genOutput.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: BlendTheme.bg4,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: color.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            _genOutput,
                            style: GoogleFonts.imFellEnglish(
                              fontSize: 12, color: BlendTheme.bright,
                              height: 1.7,
                              fontStyle: widget.node.type == NodeType.text
                                  ? FontStyle.italic : FontStyle.normal),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: BlendTheme.bg4,
              child: Row(
                children: [
                  if (!widget.isNew)
                    GestureDetector(
                      onTap: () => Navigator.pop(context, null),
                      child: Text('[delete]',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9, color: BlendTheme.err)),
                    ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('[cancel]',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9, color: BlendTheme.dim)),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, _built),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        border: Border.all(color: BlendTheme.gold.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text('[save]',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9, color: BlendTheme.gold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.jetBrainsMono(
      fontSize: 8, color: BlendTheme.dim, letterSpacing: 3),
  );

  Widget _field(TextEditingController ctrl, {required int maxLines, String hint = ''}) {
    return Container(
      decoration: BoxDecoration(
        color: BlendTheme.bg4,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: BlendTheme.border2),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.imFellEnglish(
          fontSize: 13, color: BlendTheme.bright, height: 1.6),
        cursorColor: BlendTheme.gold,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(10),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.jetBrainsMono(
            fontSize: 10, color: BlendTheme.dim.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
