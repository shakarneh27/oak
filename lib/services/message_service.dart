import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

class OakMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final String body;
  final bool read;
  final DateTime createdAt;

  const OakMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  factory OakMessage.fromMap(Map<String, dynamic> map) => OakMessage(
    id: map['id'] as String,
    senderId: map['sender_id'] as String,
    recipientId: map['recipient_id'] as String,
    body: map['body'] as String? ?? '',
    read: map['read'] as bool? ?? false,
    createdAt:
        DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Parent <-> teacher messaging over the `messages` table (RLS scopes
/// every query to conversations the caller participates in).
class MessageService {
  final SupabaseClient _client;

  MessageService(this._client);

  /// Live stream of every message visible to the signed-in user.
  Stream<List<OakMessage>> watchMyMessages() {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) => rows.map(OakMessage.fromMap).toList());
  }

  Future<void> send({
    required String recipientId,
    required String body,
    String? studentId,
  }) async {
    await _client.from('messages').insert({
      'sender_id': _client.auth.currentUser!.id,
      'recipient_id': recipientId,
      'body': body,
      if (studentId != null) 'student_id': studentId,
    });
  }

  Future<void> markRead(String messageId) async {
    await _client.from('messages').update({'read': true}).eq('id', messageId);
  }

  /// The teacher managing [classroom] — visible to parents through the
  /// `profiles_select_child_teacher` policy.
  Future<AppUser?> findTeacherForClassroom(String? classroom) async {
    if (classroom == null || classroom.isEmpty) return null;
    final rows = await _client
        .from('profiles')
        .select()
        .eq('role', 'teacher')
        .contains('managed_classrooms', [classroom])
        .limit(1);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }
}
