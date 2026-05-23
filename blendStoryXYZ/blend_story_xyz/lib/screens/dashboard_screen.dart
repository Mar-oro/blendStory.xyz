import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/blend_theme.dart';
import '../services/auth_service.dart';
import '../services/node_store.dart';
import '../models/story_node.dart';
import 'node_modal_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _filter = 'all';
  String _statusMsg = '';
  Timer? _statusTimer;
  Timer? _clockTimer;
  String _time = '';
  final _cmdCtrl = TextEditingController();
  final _cmdFocus = FocusNode();
  bool _showHelp = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) { _updateTime(); }
    });
  }

  void _updateTime() {
    final n = DateTime.now();
    setState(() {
      _time = '${n.hour.toString().padLeft(2, '0')}:'
              '${n.minute.toString().padLeft(2, '0')}:'
              '${n.second.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _cmdCtrl.dispose();
    _cmdFocus.dispose();
    _statusTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  List<StoryNode> get _visibleNodes {
    final all = NodeStore.instance.all;
    if (_filter == 'all') return all;
    final t = NodeTypeExt.fromKey(_filter);
    return all.where((n) => n.type == t).toList();
  }

  void _setStatus(String msg) {
    setState(() => _statusMsg = msg);
    _statusTimer?.cancel();
    _statusTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) { setState(() => _statusMsg = ''); }
    });
  }

  void _openCreate(NodeType type) async {
    final node = StoryNode(
      id: NodeStore.instance.nextId, type: type,
      title: '${type.label.toLowerCase()} #${NodeStore.instance.nextId - 1}',
    );
    final saved = await Navigator.push<StoryNode>(
      context,
      MaterialPageRoute(builder: (_) => NodeModalScreen(node: node, isNew: true)),
    );
    if (saved != null) {
      NodeStore.instance.add(saved);
      setState(() {});
      _setStatus('node #${saved.id} created');
    }
  }

  void _openEdit(StoryNode node) async {
    final saved = await Navigator.push<StoryNode>(
      context,
      MaterialPageRoute(builder: (_) => NodeModalScreen(node: node, isNew: false)),
    );
    if (saved != null) {
      NodeStore.instance.update(saved);
      setState(() {});
    }
  }

  void _deleteNode(int id) {
    NodeStore.instance.remove(id);
    setState(() {});
    _setStatus('node #$id deleted');
  }

  void _execCmd(String raw) {
    final cmd = raw.trim();
    _cmdCtrl.clear();
    if (cmd.isEmpty) return;

    if (cmd == '?') {
      setState(() => _showHelp = true);
      return;
    }
    if (cmd == 'esc') {
      setState(() { _showHelp = false; _filter = 'all'; });
      return;
    }
    if (cmd.startsWith(':n ') || cmd.startsWith('n ')) {
      final type = cmd.split(' ').last.trim();
      final t = {'text': NodeType.text, 'image': NodeType.image,
                 'audio': NodeType.audio, 'float': NodeType.float}[type];
      if (t != null) { _openCreate(t); } else { _setStatus('unknown type: $type'); }
      return;
    }
    if (cmd.startsWith(':del #') || cmd.startsWith('del #')) {
      final id = int.tryParse(cmd.split('#').last.trim());
      if (id != null) {
        _deleteNode(id);
      } else {
        _setStatus('invalid id');
      }
      return;
    }
    if (cmd.startsWith(':filter ') || cmd.startsWith('filter ')) {
      final f = cmd.split(' ').last.trim();
      setState(() => _filter = f);
      _setStatus('filter: $f');
      return;
    }
    if (cmd == ':clear' || cmd == 'clear') {
      NodeStore.instance.clear().then((_) {
        if (mounted) { setState(() {}); _setStatus('all nodes cleared'); }
      });
      return;
    }
    if (cmd == ':logout' || cmd == 'logout') {
      BlendAuthService.instance.logout();
      Navigator.pushReplacementNamed(context, '/');
      return;
    }
    _setStatus('unknown command: $cmd');
  }

  void _logout() {
    BlendAuthService.instance.logout();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final user  = BlendAuthService.instance.username ?? 'author';
    final nodes = _visibleNodes;

    return Scaffold(
      backgroundColor: BlendTheme.bg2,
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (e) {
          if (e is KeyDownEvent) {
            if (e.logicalKey == LogicalKeyboardKey.escape) {
              setState(() => _showHelp = false);
            }
          }
        },
        child: Column(
          children: [
            _StatusBar(user: user, time: _time, onLogout: _logout),
            _TabBar(
              current: _filter,
              onTab: (t) => setState(() => _filter = t),
              onCreate: _openCreate,
            ),
            Expanded(
              child: Stack(
                children: [
                  nodes.isEmpty ? _buildEmpty() : _buildGrid(nodes),
                  if (_showHelp) _HelpOverlay(onClose: () => setState(() => _showHelp = false)),
                ],
              ),
            ),
            _CommandBar(
              ctrl: _cmdCtrl,
              focus: _cmdFocus,
              status: _statusMsg,
              onSubmit: _execCmd,
              onNew: () => _openCreate(NodeType.text),
              onHelp: () => setState(() => _showHelp = !_showHelp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('no nodes yet',
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: BlendTheme.dim)),
          const SizedBox(height: 8),
          Text('press [n] or type :n text to create one',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: BlendTheme.dim.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildGrid(List<StoryNode> nodes) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 1.15,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: nodes.length,
      itemBuilder: (_, i) => _NodeCard(
        node: nodes[i],
        onEdit:   () => _openEdit(nodes[i]),
        onDelete: () => _deleteNode(nodes[i].id),
        onGen:    () => _openEdit(nodes[i]),
      ),
    );
  }
}

// ── Status Bar ────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final String user, time;
  final VoidCallback onLogout;
  const _StatusBar({required this.user, required this.time, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: BlendTheme.bg4,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _chip('blendStory', BlendTheme.gold),
          const SizedBox(width: 6),
          _chip('● $user', BlendTheme.body),
          const SizedBox(width: 6),
          _chip('● #float', BlendTheme.floatColor),
          const SizedBox(width: 6),
          _chip('● #text', BlendTheme.textColor),
          const SizedBox(width: 6),
          _chip('● #img', BlendTheme.imageColor),
          const SizedBox(width: 6),
          _chip('● #audio', BlendTheme.audioColor),
          const Spacer(),
          Text(time,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9, color: BlendTheme.dim)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onLogout,
            child: Text('logout',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9, color: BlendTheme.dim,
                decoration: TextDecoration.underline,
                decorationColor: BlendTheme.dim)),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color c) => Text(
    label,
    style: GoogleFonts.jetBrainsMono(fontSize: 8, color: c),
  );
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final String current;
  final ValueChanged<String> onTab;
  final ValueChanged<NodeType> onCreate;
  const _TabBar({required this.current, required this.onTab, required this.onCreate});

  static const _tabs = [
    ('ALL', 'all'),
    ('◈ FLOAT', 'float'),
    ('⬡ TEXT', 'text'),
    ('◉ IMAGE', 'image'),
    ('♫ AUDIO', 'audio'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: BlendTheme.bg3,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          ..._tabs.map((t) => _Tab(
            label: t.$1, active: current == t.$2,
            onTap: () => onTab(t.$2),
          )),
          const Spacer(),
          GestureDetector(
            onTap: () => _showNewMenu(context, onCreate),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: BlendTheme.gold.withValues(alpha: 0.1),
                border: Border.all(color: BlendTheme.gold.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text('+ NEW',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9, color: BlendTheme.gold, letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewMenu(BuildContext context, ValueChanged<NodeType> onCreate) {
    showMenu(
      context: context,
      color: BlendTheme.bg4,
      position: const RelativeRect.fromLTRB(1000, 68, 8, 0),
      items: NodeType.values.map((t) => PopupMenuItem(
        value: t,
        child: Text('${t.icon}  ${t.label}',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10, color: BlendTheme.nodeColor(t.key))),
      )).toList(),
    ).then((t) { if (t != null) { onCreate(t); } });
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? BlendTheme.gold : Colors.transparent,
              width: 1.5),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: active ? BlendTheme.gold : BlendTheme.dim,
            letterSpacing: 1),
        ),
      ),
    );
  }
}

// ── Node Card ─────────────────────────────────────────────────────────────────

class _NodeCard extends StatefulWidget {
  final StoryNode node;
  final VoidCallback onEdit, onDelete, onGen;
  const _NodeCard({required this.node, required this.onEdit,
      required this.onDelete, required this.onGen});
  @override State<_NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends State<_NodeCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final node  = widget.node;
    final color = BlendTheme.nodeColor(node.type.key);
    return GestureDetector(
      onTap: widget.onEdit,
      onTapDown: (_) => setState(() => _hover = true),
      onTapUp:   (_) => setState(() => _hover = false),
      onTapCancel: ()  => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: BlendTheme.bg3,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _hover ? color.withValues(alpha: 0.5) : BlendTheme.border2),
          boxShadow: _hover ? [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 16),
          ] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  Text(node.type.icon,
                    style: TextStyle(fontSize: 16, color: color)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      node.type.label,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8, color: color, letterSpacing: 2),
                    ),
                  ),
                  Text('#${node.id}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8, color: BlendTheme.dim)),
                ],
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                node.title,
                style: GoogleFonts.imFellEnglish(
                  fontSize: 14, color: BlendTheme.bright,
                  fontStyle: FontStyle.italic),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            // Content preview
            if (node.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Text(
                  node.content,
                  style: GoogleFonts.imFellEnglish(
                    fontSize: 10, color: BlendTheme.body, height: 1.5),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
            // Image/audio placeholder
            if (node.type == NodeType.image && node.content.isEmpty)
              _ImagePlaceholder(color: color),
            if (node.type == NodeType.audio && node.content.isEmpty)
              _AudioPlaceholder(color: color),
            const Spacer(),
            // Footer buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: BlendTheme.border))),
              child: Row(
                children: [
                  _CardBtn(label: 'edit', onTap: widget.onEdit),
                  const SizedBox(width: 6),
                  _CardBtn(label: 'del', onTap: widget.onDelete, danger: true),
                  if (node.type.canGenerate) ...[
                    const Spacer(),
                    _CardBtn(label: 'gen ▶', onTap: widget.onGen, accent: true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final Color color;
  const _ImagePlaceholder({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), BlendTheme.bg3],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Text('◉', style: TextStyle(fontSize: 20, color: color.withValues(alpha: 0.3))),
      ),
    );
  }
}

class _AudioPlaceholder extends StatelessWidget {
  final Color color;
  const _AudioPlaceholder({required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Text(
        kWaveform,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 7, color: color.withValues(alpha: 0.5)),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _CardBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool accent;
  const _CardBtn({required this.label, required this.onTap,
      this.danger = false, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final c = danger ? BlendTheme.err : accent ? BlendTheme.gold : BlendTheme.dim;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: c.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text('[$label]',
          style: GoogleFonts.jetBrainsMono(fontSize: 8, color: c)),
      ),
    );
  }
}

// ── Command Bar ───────────────────────────────────────────────────────────────

class _CommandBar extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final String status;
  final ValueChanged<String> onSubmit;
  final VoidCallback onNew, onHelp;
  const _CommandBar({required this.ctrl, required this.focus,
      required this.status, required this.onSubmit,
      required this.onNew, required this.onHelp});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: BlendTheme.bg4,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Text(':',
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: BlendTheme.gold)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: ctrl,
              focusNode: focus,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11, color: BlendTheme.bright),
              cursorColor: BlendTheme.gold,
              onSubmitted: onSubmit,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: status.isNotEmpty ? status : 'command...',
                hintStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: status.isNotEmpty ? BlendTheme.dim : BlendTheme.dim.withValues(alpha: 0.4)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CmdChip(label: '[n]ew', onTap: onNew),
          const SizedBox(width: 6),
          _CmdChip(label: '[?]help', onTap: onHelp),
          const SizedBox(width: 6),
          _CmdChip(label: '[esc]', onTap: () => focus.unfocus()),
        ],
      ),
    );
  }
}

class _CmdChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CmdChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 8, color: BlendTheme.dim)),
    );
  }
}

// ── Help Overlay ──────────────────────────────────────────────────────────────

class _HelpOverlay extends StatelessWidget {
  final VoidCallback onClose;
  const _HelpOverlay({required this.onClose});

  static const _cmds = [
    (':n text',    'new text node'),
    (':n image',   'new image node'),
    (':n audio',   'new audio node'),
    (':n float',   'new floating note'),
    (':del #id',   'delete node by ID'),
    (':filter t',  'filter by type'),
    (':clear',     'clear all nodes'),
    (':logout',    'logout'),
    ('?',          'show this help'),
    ('Esc',        'close help / blur input'),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: BlendTheme.bg4,
                border: Border.all(color: BlendTheme.border2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('COMMANDS',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, color: BlendTheme.gold, letterSpacing: 3)),
                      const Spacer(),
                      GestureDetector(
                        onTap: onClose,
                        child: Text('[esc]',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9, color: BlendTheme.dim)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ..._cmds.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(c.$1,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10, color: BlendTheme.goldE)),
                        ),
                        Text('— ${c.$2}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10, color: BlendTheme.dim)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
