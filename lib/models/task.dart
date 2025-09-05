class Task {
  final int? id;
  final String title;
  final DateTime deadline;
  final bool completed;

  Task({
    this.id,
    required this.title,
    required this.deadline,
    this.completed = false,
  }) : assert(title.isNotEmpty, 'Title cannot be empty'); // Validation

  Task copyWith({int? id, String? title, DateTime? deadline, bool? completed}) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      deadline: deadline ?? this.deadline,
      completed: completed ?? this.completed,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime parsedDeadline;
    try {
      parsedDeadline = DateTime.parse(json['deadline'] as String);
    } catch (e) {
      // Handle parsing error, e.g., log it, throw a custom exception, or use a default
      // For now, we'll throw a more informative error.
      throw FormatException('Invalid deadline format: ${json['deadline']}');
    }

    return Task(
      id: json['id'] as int?,
      title: json['title'] as String,
      deadline: parsedDeadline, // Use the parsed deadline
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'deadline': deadline.toIso8601String(),
      'completed': completed,
    };
  }

  // Added getter for isOverdue
  bool get isOverdue => !completed && deadline.isBefore(DateTime.now());
}
