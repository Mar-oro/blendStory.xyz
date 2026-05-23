
enum NodeType { float, text, image, audio }

extension NodeTypeExt on NodeType {
  String get key {
    switch (this) {
      case NodeType.float: return 'float';
      case NodeType.text:  return 'text';
      case NodeType.image: return 'image';
      case NodeType.audio: return 'audio';
    }
  }

  String get label {
    switch (this) {
      case NodeType.float: return 'FLOAT';
      case NodeType.text:  return 'TEXT';
      case NodeType.image: return 'IMAGE';
      case NodeType.audio: return 'AUDIO';
    }
  }

  String get icon {
    switch (this) {
      case NodeType.float: return '◈';
      case NodeType.text:  return '⬡';
      case NodeType.image: return '◉';
      case NodeType.audio: return '♫';
    }
  }

  bool get canGenerate => this != NodeType.float;

  static NodeType fromKey(String k) {
    switch (k) {
      case 'float': return NodeType.float;
      case 'text':  return NodeType.text;
      case 'image': return NodeType.image;
      case 'audio': return NodeType.audio;
      default:      return NodeType.float;
    }
  }
}

class StoryNode {
  final int id;
  final NodeType type;
  String title;
  String content;
  String prompt;
  String generatedOutput;
  final DateTime created;

  StoryNode({
    required this.id,
    required this.type,
    required this.title,
    this.content = '',
    this.prompt = '',
    this.generatedOutput = '',
    DateTime? created,
  }) : created = created ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.key,
    'title': title,
    'content': content,
    'prompt': prompt,
    'generatedOutput': generatedOutput,
    'created': created.millisecondsSinceEpoch,
  };

  factory StoryNode.fromJson(Map<String, dynamic> j) => StoryNode(
    id: j['id'] as int,
    type: NodeTypeExt.fromKey(j['type'] as String),
    title: j['title'] as String,
    content: j['content'] as String? ?? '',
    prompt: j['prompt'] as String? ?? '',
    generatedOutput: j['generatedOutput'] as String? ?? '',
    created: DateTime.fromMillisecondsSinceEpoch(j['created'] as int),
  );
}

// ── Default seed nodes ────────────────────────────────────────────────────────

final kSeedNodes = [
  StoryNode(
    id: 1, type: NodeType.float, title: 'fragment',
    content: 'the robot dreams in amber light, waiting for a signal that never comes. — quick idea, 2am',
  ),
  StoryNode(
    id: 2, type: NodeType.text, title: 'chapter one — draft',
    content: 'She walked through the neon rain, each droplet catching the light of a thousand signs she could no longer read. The city breathed around her like a sleeping giant, unaware of the single figure threading through its exhaust-stained lungs.',
  ),
  StoryNode(
    id: 3, type: NodeType.image, title: 'neon city scene',
    prompt: 'aerial view of rain-slicked city at night, amber streetlights, silhouette figure, cinematic, hyperrealistic',
  ),
  StoryNode(
    id: 4, type: NodeType.audio, title: 'ambient score',
    prompt: 'slow ambient drone, minor key, resonant bass, sparse piano, urban nightscape atmosphere',
  ),
];

// ── Mock generation content ───────────────────────────────────────────────────

const kMockTextOutputs = [
  'The amber light flickered once, twice, then settled into its slow pulse rhythm. She had been waiting three hours. The city did not notice.',
  'In the space between thoughts, a frequency — low, persistent, like the hum of servers processing grief.',
  'Every story begins before you notice it beginning. This one started six years ago, in a server room that smelled of ozone and cold coffee.',
  'He wrote the same sentence forty times. On the forty-first attempt, something changed in the light.',
];

const kWaveform = '▁▂▃▄▅▆▇▆▅▄▃▂▁▂▃▄▅▆▅▄▃▂▁▂▃▄▅▆▇▅▃▂▁';
