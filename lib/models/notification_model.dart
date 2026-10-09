enum NotificationType {
  friendRequest,
  friendAccepted,
  newChallenge,
  challengeCompleted,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String? targetPuzzleHash;
  final String? relatedId;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.targetPuzzleHash,
    this.relatedId,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'message': message,
        'targetPuzzleHash': targetPuzzleHash,
        'relatedId': relatedId,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] ?? '',
        type: NotificationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => NotificationType.friendRequest,
        ),
        title: json['title'] ?? 'Notification',
        message: json['message'] ?? '',
        targetPuzzleHash: json['targetPuzzleHash'],
        relatedId: json['relatedId'],
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        isRead: json['isRead'] ?? false,
      );
}
