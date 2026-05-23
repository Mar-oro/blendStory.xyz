import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/story_node.dart';

class NodeStore {
  NodeStore._();
  static final instance = NodeStore._();

  final List<StoryNode> _nodes = [];
  int _nextId = 10;

  List<StoryNode> get all => List.unmodifiable(_nodes);
  List<StoryNode> byType(NodeType t) => _nodes.where((n) => n.type == t).toList();
  int get nextId => _nextId++;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(AppConfig.storageKey);
    final nid   = prefs.getInt(AppConfig.storageNidKey);
    if (nid != null) _nextId = nid;
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _nodes.clear();
      _nodes.addAll(list.map((j) => StoryNode.fromJson(j as Map<String, dynamic>)));
    } else {
      _nodes.addAll(kSeedNodes);
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.storageKey, jsonEncode(_nodes.map((n) => n.toJson()).toList()));
    await prefs.setInt(AppConfig.storageNidKey, _nextId);
  }

  void add(StoryNode node) {
    _nodes.insert(0, node);
    save();
  }

  void update(StoryNode node) {
    final i = _nodes.indexWhere((n) => n.id == node.id);
    if (i >= 0) { _nodes[i] = node; save(); }
  }

  void remove(int id) {
    _nodes.removeWhere((n) => n.id == id);
    save();
  }

  Future<void> clear() async {
    _nodes.clear();
    _nextId = 10;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.storageKey);
    await prefs.remove(AppConfig.storageNidKey);
  }
}
