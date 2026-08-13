import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/chat_message.dart';
import '../models/chat_room_model.dart';

class SupabaseChatRepository {
  final ApiClient _apiClient;
  final SupabaseClient? _client;

  SupabaseChatRepository({required ApiClient apiClient, SupabaseClient? client})
    : _apiClient = apiClient,
      _client = client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // ID Generation
  // ---------------------------------------------------------------------------

  /// Generates a UUID v4 without any external package.
  static String _generateId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // version 4
    values[8] = (values[8] & 0x3f) | 0x80; // variant
    final hex = values.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  // ---------------------------------------------------------------------------
  // Prescription Chat — still uses backend API
  // ---------------------------------------------------------------------------

  /// Opens/Initialises a prescription chat room via the backend REST API and
  /// optionally marks a notification as read.
  Future<String> openPrescriptionChat({
    required String patientId,
    required String prescriptionUrl,
    String? notes,
    String? partnerId,
    String? notificationId,
  }) async {
    String? chatId;

    // 1. Try initPrescriptionThread backend REST API
    if (patientId.isNotEmpty) {
      try {
        final response = await _apiClient.post(
          ApiEndpoints.prescriptionThreadInit,
          data: {
            'patientId': patientId,
            'prescriptionUrl': prescriptionUrl,
            'notes': notes,
          },
        );
        if (response.statusCode == 200 && response.data != null) {
          final resData = response.data['data'] as Map<String, dynamic>;
          chatId =
              resData['chatId']?.toString() ??
              resData['chat']?['id']?.toString();
        }
      } catch (e) {
        debugPrint(
          '[SupabaseChatRepository] openPrescriptionChat initPrescriptionThread error: $e',
        );
      }
    }

    // 2. Fallback — getOrCreateChatRoom directly in Supabase
    if ((chatId == null || chatId.isEmpty) &&
        patientId.isNotEmpty &&
        partnerId != null &&
        partnerId.isNotEmpty) {
      try {
        final room = await getOrCreateChatRoom(
          patientId: patientId,
          partnerId: partnerId,
        );
        chatId = room.id;
      } catch (e) {
        debugPrint(
          '[SupabaseChatRepository] openPrescriptionChat getOrCreateChatRoom error: $e',
        );
      }
    }

    // 3. Mark notification as read
    if (notificationId != null && notificationId.isNotEmpty) {
      try {
        await _apiClient.patch(ApiEndpoints.notificationRead(notificationId));
      } catch (e) {
        debugPrint(
          '[SupabaseChatRepository] openPrescriptionChat markNotificationAsRead error: $e',
        );
      }
    }

    if (chatId != null && chatId.isNotEmpty) return chatId;
    throw Exception('Failed to open prescription chat room');
  }

  Future<ChatRoomModel> getOrCreateChatRoom({
    required String patientId,
    required String partnerId,
    String? patientName,
    String? patientPhotoUrl,
    String? partnerName,
    String? partnerPhotoUrl,
  }) async {
    final existing = await _supabase
        .from('chats')
        .select()
        .eq('patient_id', patientId)
        .eq('partner_id', partnerId)
        .maybeSingle();

    if (existing != null) return ChatRoomModel.fromJson(existing);

    final inserted = await _supabase
        .from('chats')
        .insert({
          'id': _generateId(),
          'patient_id': patientId,
          'partner_id': partnerId,
          'patient_name': patientName ?? 'Patient',
          if (patientPhotoUrl != null) 'patient_photo_url': patientPhotoUrl,
          'partner_name': partnerName ?? 'Pharmacy Partner',
          if (partnerPhotoUrl != null) 'partner_photo_url': partnerPhotoUrl,
          'partner_unread_count': 0,
          'patient_unread_count': 0,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    return ChatRoomModel.fromJson(inserted);
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  /// Streams all chat rooms for a pharmacy partner ordered by most recent
  /// message first.
  Stream<List<ChatRoomModel>> streamPartnerChats(String partnerId) {
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('partner_id', partnerId)
        .order('last_message_time', ascending: false)
        .map((list) => list.map((m) => ChatRoomModel.fromJson(m)).toList());
  }

  final Map<String, DateTime> _threadLastReadTimes = {};

  /// Streams only root messages (parent_message_id IS NULL) for a chat room.
  ///
  /// Dynamically computes reply counts and unread reply counts from incoming
  /// real-time stream messages, and sorts root messages descending by created_at.
  Stream<List<ChatMessage>> streamRootMessages(String chatId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .map((dataList) {
          final allMessages = dataList
              .map((map) => ChatMessage.fromJson(map))
              .toList();

          final rootMaps = dataList
              .where(
                (m) =>
                    m['parent_message_id'] == null ||
                    (m['parent_message_id'] as String?)?.trim().isEmpty == true,
              )
              .toList();

          final replyMessages = allMessages
              .where((m) => !m.isRootMessage)
              .toList();

          final rootMessages = rootMaps.map((map) {
            final rootMsg = ChatMessage.fromJson(map);
            final repliesForRoot = replyMessages
                .where((r) => r.parentMessageId == rootMsg.id)
                .toList();

            final calculatedReplyCount = max(
              rootMsg.replyCount,
              repliesForRoot.length,
            );

            int calculatedUnreadReplyCount = rootMsg.unreadReplyCount;
            final lastReadTime = _threadLastReadTimes[rootMsg.id];

            final patientReplies = repliesForRoot
                .where((r) => r.senderRole == 'PATIENT' || !r.isSentByPartner)
                .toList();

            if (lastReadTime != null) {
              calculatedUnreadReplyCount = patientReplies
                  .where((r) => r.createdAt.isAfter(lastReadTime))
                  .length;
            } else if (calculatedUnreadReplyCount == 0 &&
                patientReplies.isNotEmpty) {
              calculatedUnreadReplyCount = patientReplies.length;
            }

            return ChatMessage(
              id: rootMsg.id,
              chatId: rootMsg.chatId,
              senderId: rootMsg.senderId,
              senderRole: rootMsg.senderRole,
              content: rootMsg.content,
              imageUrl: rootMsg.imageUrl,
              parentMessageId: rootMsg.parentMessageId,
              replyCount: calculatedReplyCount,
              unreadReplyCount: calculatedUnreadReplyCount,
              isPrescription: rootMsg.isPrescription,
              createdAt: rootMsg.createdAt,
            );
          }).toList();

          // Order root messages in descending order of created_at
          rootMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return rootMessages;
        });
  }

  /// Streams all replies for a specific root message (thread).
  Stream<List<ChatMessage>> streamThreadReplies(String parentMessageId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('parent_message_id', parentMessageId)
        .order('created_at', ascending: true)
        .map((list) => list.map((m) => ChatMessage.fromJson(m)).toList());
  }

  // ---------------------------------------------------------------------------
  // Send Message
  // ---------------------------------------------------------------------------

  /// Inserts a new message directly into Supabase and updates the parent chat
  /// row (last_message, last_message_time, unread counts).
  ///
  /// When [parentMessageId] is provided the message is treated as a reply and
  /// the parent message's [reply_count] / [unread_reply_count] are also updated.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderRole, // 'PARTNER' or 'PATIENT' (matches DB enum)
    required String content,
    String? imageUrl,
    String? parentMessageId,
    bool isPrescription = false,
    String? partnerName,
    String? patientId,
  }) async {
    final String? validParentId =
        (parentMessageId != null && parentMessageId.trim().isNotEmpty)
        ? parentMessageId.trim()
        : null;

    final String messageId = _generateId();
    final DateTime now = DateTime.now().toUtc();

    try {
      // 1. Insert the new message row
      await _supabase.from('messages').insert({
        'id': messageId,
        'chat_id': chatId,
        'sender_id': senderId,
        'sender_role': senderRole,
        'content': content,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        if (validParentId != null) 'parent_message_id': validParentId,
        'is_prescription': isPrescription,
        'reply_count': 0,
        'unread_reply_count': 0,
        'created_at': now.toIso8601String(),
      });

      // 2. If this is a reply → increment reply_count (and unread_reply_count
      //    only when the patient is replying, so the partner sees the badge)
      if (validParentId != null) {
        final parentRow = await _supabase
            .from('messages')
            .select('reply_count, unread_reply_count')
            .eq('id', validParentId)
            .maybeSingle();

        if (parentRow != null) {
          final int currentReply = (parentRow['reply_count'] as int? ?? 0);
          final int currentUnread =
              (parentRow['unread_reply_count'] as int? ?? 0);

          await _supabase
              .from('messages')
              .update({
                'reply_count': currentReply + 1,
                // Increment unread for the PARTNER when the PATIENT sends a reply
                if (senderRole == 'PATIENT')
                  'unread_reply_count': currentUnread + 1,
              })
              .eq('id', validParentId);
        }
      }

      // 3. Update the chats row: last_message, last_message_time, unread counts
      final chatRow = await _supabase
          .from('chats')
          .select('patient_unread_count, partner_unread_count')
          .eq('id', chatId)
          .maybeSingle();

      if (chatRow != null) {
        final int partnerUnread =
            (chatRow['partner_unread_count'] as int? ?? 0);
        final int patientUnread =
            (chatRow['patient_unread_count'] as int? ?? 0);

        await _supabase
            .from('chats')
            .update({
              'last_message': content,
              'last_message_time': now.toIso8601String(),
              // When partner sends → increment patient's unread
              if (senderRole == 'PARTNER')
                'patient_unread_count': patientUnread + 1,
              // When patient sends → increment partner's unread
              if (senderRole == 'PATIENT')
                'partner_unread_count': partnerUnread + 1,
            })
            .eq('id', chatId);
      }

      // 4. Send push notification to target patient when partner sends a message
      if (senderRole == 'PARTNER') {
        final String? targetPatientId =
            (patientId != null && patientId.isNotEmpty)
                ? patientId
                : chatRow?['patient_id']?.toString();

        if (targetPatientId != null && targetPatientId.isNotEmpty) {
          final String title =
              (partnerName != null && partnerName.trim().isNotEmpty)
                  ? partnerName.trim()
                  : (chatRow?['partner_name']?.toString() ??
                      'Pharmacy Partner');

          // Limit title to max 200 chars and body to max 1000 chars as per API spec
          final safeTitle =
              title.length > 200 ? title.substring(0, 200) : title;
          final safeBody =
              content.length > 1000 ? content.substring(0, 1000) : content;

          final Map<String, String> dataPayload = {
            'chatId': chatId,
            'type': 'chat',
            if (validParentId != null) 'parentMessageId': validParentId,
          };

          // Safe, best-effort dispatch (does not throw)
          await sendPushNotification(
            userId: targetPatientId,
            role: 'patient',
            title: safeTitle,
            body: safeBody,
            imageUrl: imageUrl,
            data: dataPayload,
          );
        }
      }
    } catch (e) {
      debugPrint('[SupabaseChatRepository] sendMessage error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Push Notification
  // ---------------------------------------------------------------------------

  /// Sends a push notification to a user (patient or partner) by userId and role.
  Future<bool> sendPushNotification({
    required String userId,
    required String role, // 'patient' | 'partner'
    required String title,
    required String body,
    String? imageUrl,
    Map<String, String>? data,
  }) async {
    try {
      debugPrint(
        '[SupabaseChatRepository] Sending push notification to $role ($userId): $title - $body',
      );
      final response = await _apiClient.post(
        ApiEndpoints.pushNotificationUser,
        data: {
          'userId': userId,
          'role': role,
          'title': title,
          'body': body,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
          if (data != null && data.isNotEmpty) 'data': data,
        },
      );

      if (response.statusCode == 200) {
        debugPrint(
          '[SupabaseChatRepository] Push notification sent successfully: ${response.data}',
        );
        return true;
      } else {
        debugPrint(
          '[SupabaseChatRepository] Push notification response status: ${response.statusCode}, data: ${response.data}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[SupabaseChatRepository] sendPushNotification error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Mark as Read
  // ---------------------------------------------------------------------------

  /// Resets the partner's unread count on the chat row to 0.
  Future<void> markPartnerChatsUnreadAsRead(String chatId) async {
    try {
      await _supabase
          .from('chats')
          .update({'partner_unread_count': 0})
          .eq('id', chatId);
    } catch (e) {
      debugPrint(
        '[SupabaseChatRepository] markPartnerChatsUnreadAsRead error: $e',
      );
    }
  }

  /// Resets the unread_reply_count on a root message to 0 when the partner
  /// opens that thread.
  Future<void> markThreadUnreadAsRead(String parentMessageId) async {
    _threadLastReadTimes[parentMessageId] = DateTime.now();
    try {
      await _supabase
          .from('messages')
          .update({'unread_reply_count': 0})
          .eq('id', parentMessageId);
    } catch (e) {
      debugPrint('[SupabaseChatRepository] markThreadUnreadAsRead error: $e');
    }
  }
}
