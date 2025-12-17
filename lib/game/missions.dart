import 'dart:core';

enum MissionType {
  score,
  combo,
  frenzy,
}

class Mission {
  final String id;
  final MissionType type;
  final int target;
  bool completed;

  Mission({
    required this.id,
    required this.type,
    required this.target,
    this.completed = false,
  });

  String get description {
    switch (type) {
      case MissionType.score:
        return 'Score $target+ in a run';
      case MissionType.combo:
        return 'Reach combo $target+';
      case MissionType.frenzy:
        return 'Trigger Frenzy $target time(s)';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'target': target,
      'completed': completed,
    };
  }

  factory Mission.fromMap(Map<String, dynamic> map) {
    return Mission(
      id: map['id'] as String,
      type: MissionType.values[map['type'] as int],
      target: map['target'] as int,
      completed: (map['completed'] as bool?) ?? false,
    );
  }
}
