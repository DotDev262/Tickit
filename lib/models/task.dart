class Task {
  String? id;
  final String title;
  final DateTime deadline;
  final String userId;
  final bool completed; // Added completed field

  Task({
    this.id,
    required this.title,
    required this.deadline,
    required this.userId,
    this.completed = false, // Default to false
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString(), // Convert id to String
      title: json['title'],
      deadline: DateTime.parse(json['deadline']),
      userId: json['user_id'],
      completed: json['completed'] ?? false, // Parse completed, default to false
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'title': title,
      'deadline': deadline.toIso8601String(),
      'user_id': userId,
      'completed': completed, // Include completed in toJson
    };
    if (id != null) {
      json['id'] = id!;
    }
    return json;
  }

  Task copyWith({
    String? id,
    String? title,
    DateTime? deadline,
    String? userId,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      deadline: deadline ?? this.deadline,
      userId: userId ?? this.userId,
      completed: completed ?? this.completed,
    );
  }
}