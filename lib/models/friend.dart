class UserProfile {
  final String id;
  final String publicId;
  final String displayName;

  UserProfile({
    required this.id,
    required this.publicId,
    required this.displayName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'publicId': publicId,
        'displayName': displayName,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] ?? '',
        publicId: json['publicId'] ?? json['public_id'] ?? '',
        displayName: json['displayName'] ?? json['display_name'] ?? 'Player',
      );
}

class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromPublicId;
  final String fromUserName;
  final String toUserId;
  final String toPublicId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromPublicId,
    required this.fromUserName,
    required this.toUserId,
    required this.toPublicId,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUserId': fromUserId,
        'fromPublicId': fromPublicId,
        'fromUserName': fromUserName,
        'toUserId': toUserId,
        'toPublicId': toPublicId,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        id: json['id'] ?? '',
        fromUserId: json['fromUserId'] ?? json['from_user_id'] ?? '',
        fromPublicId: json['fromPublicId'] ?? json['from_public_id'] ?? '',
        fromUserName: json['fromUserName'] ?? json['from_user_name'] ?? 'Player',
        toUserId: json['toUserId'] ?? json['to_user_id'] ?? '',
        toPublicId: json['toPublicId'] ?? json['to_public_id'] ?? '',
        status: json['status'] ?? 'pending',
        createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      );
}

class Friendship {
  final String id;
  final String userId;
  final String friendUserId;
  final String friendPublicId;
  final String friendName;
  final DateTime createdAt;

  Friendship({
    required this.id,
    required this.userId,
    required this.friendUserId,
    required this.friendPublicId,
    required this.friendName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'friendUserId': friendUserId,
        'friendPublicId': friendPublicId,
        'friendName': friendName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
        id: json['id'] ?? '',
        userId: json['userId'] ?? json['user_id'] ?? '',
        friendUserId: json['friendUserId'] ?? json['friend_user_id'] ?? '',
        friendPublicId: json['friendPublicId'] ?? json['friend_public_id'] ?? '',
        friendName: json['friendName'] ?? json['friend_name'] ?? 'Friend',
        createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      );
}
