class Task {
  final String id;
  final String title;
  final String description;
  final String location;
  final String? startDate;
  final String? startTime;
  final String? dueDate;
  final String? dueTime;
  final String category;
  final String difficulty;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.startTime,
    required this.dueDate,
    required this.dueTime,
    required this.category,
    required this.difficulty
  });

  // Factory method to create a Task from Firestore data
  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      startDate: map['startDate'],
      startTime: map['startTime'],
      dueDate: map['dueDate'],
      dueTime: map['dueTime'],
      category: map['category'],
      difficulty: map['difficulty']
    );
  }
}
