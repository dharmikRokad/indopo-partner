import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/chat_message.dart';
import '../models/chat_room_model.dart';
import 'app_config_repo.dart';

class SupabaseChatRepository {
  final ApiClient _apiClient;
  final SupabaseClient? _client;
  final AppConfigRepository _appConfigRepo;

  SupabaseChatRepository({
    required ApiClient apiClient,
    SupabaseClient? client,
    required AppConfigRepository appConfigRepo,
  })  : _apiClient = apiClient,
        _client = client,
        _appConfigRepo = appConfigRepo;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Fetches user chat rooms using Backend REST API (GET /api/chat/my-chats)
  Future<List<ChatRoomModel>> fetchMyChats() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myChats);
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        final list = resData['chats'] as List? ?? [];
        return list
            .map((json) => ChatRoomModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('[SupabaseChatRepository] fetchMyChats REST error: $e');
    }
    return [];
  }

  /// Retrieves an existing chat room between a patient and partner if one exists,
  /// otherwise creates a new chat room in the 'chats' Supabase table.
  Future<ChatRoomModel> getOrCreateChatRoom({
    required String patientId,
    required String partnerId,
    String? patientName,
    String? patientPhotoUrl,
    String? partnerName,
    String? partnerPhotoUrl,
  }) async {
    try {
      final existingChat = await _supabase
          .from('chats')
          .select()
          .eq('patient_id', patientId)
          .eq('partner_id', partnerId)
          .maybeSingle();

      if (existingChat != null) {
        return ChatRoomModel.fromJson(existingChat);
      }

      final newChatData = {
        'patient_id': patientId,
        'partner_id': partnerId,
        'patient_name': patientName ?? 'Patient',
        'patient_photo_url': patientPhotoUrl,
        'partner_name': partnerName ?? 'Pharmacy Partner',
        'partner_photo_url': partnerPhotoUrl,
        'partner_unread_count': 0,
        'patient_unread_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      final inserted = await _supabase
          .from('chats')
          .insert(newChatData)
          .select()
          .single();

      return ChatRoomModel.fromJson(inserted);
    } catch (e) {
      print('[SupabaseChatRepository] getOrCreateChatRoom error: $e');
      rethrow;
    }
  }

  /// Initializes / Opens a prescription thread via Backend REST API (POST /api/chat/prescription-thread)
  Future<Map<String, dynamic>> initPrescriptionThread({
    required String patientId,
    required String prescriptionUrl,
    String? notes,
  }) async {
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
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      print('[SupabaseChatRepository] initPrescriptionThread error: $e');
      rethrow;
    }
    throw Exception('Failed to initialize prescription thread');
  }

  /// Fetches main root messages for a chat room via Backend REST API (GET /api/chat/:chatId/messages)
  Future<List<ChatMessage>> fetchChatMessages(String chatId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.chatMessages(chatId));
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        final list = resData['messages'] as List? ?? [];
        return list
            .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('[SupabaseChatRepository] fetchChatMessages REST error, falling back to Supabase: $e');
      try {
        final res = await _supabase
            .from('messages')
            .select()
            .eq('chat_id', chatId)
            .order('created_at', ascending: true);
        return (res as List)
            .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (err) {
        print('[SupabaseChatRepository] fetchChatMessages Supabase fallback error: $err');
      }
    }
    return [];
  }

  /// Fetches inner thread replies for a prescription inquiry via Backend REST API (GET /api/chat/thread/:parentMessageId)
  Future<Map<String, dynamic>> fetchThreadReplies(String parentMessageId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.chatThreadReplies(parentMessageId));
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        final repliesList = resData['replies'] as List? ?? [];
        final replies = repliesList
            .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
            .toList();
        return {
          'parentMessage': resData['parentMessage'],
          'replies': replies,
        };
      }
    } catch (e) {
      print('[SupabaseChatRepository] fetchThreadReplies REST error: $e');
    }
    return {'parentMessage': null, 'replies': <ChatMessage>[]};
  }

  /// Streams real-time live messages for a specific chat room via Supabase while in Chat Screen
  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((dataList) {
          return dataList.map((map) => ChatMessage.fromJson(map)).toList();
        });
  }

  /// Streams active chat rooms for a pharmacy partner via Supabase
  Stream<List<ChatRoomModel>> streamPartnerChats(String partnerId) {
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('partner_id', partnerId)
        .order('last_message_time', ascending: false)
        .map((dataList) {
          return dataList.map((map) => ChatRoomModel.fromJson(map)).toList();
        });
  }

  /// Sends a chat message via Backend REST API (POST /api/chat/send) and updates real-time Supabase table
  Future<void> sendMessage({
    required String chatId,
    required String appointmentId,
    required String senderId,
    required String senderRole, // 'partner' or 'patient'
    required String content,
    String? imageUrl,
    String? parentMessageId,
  }) async {
    try {
      // 1. Send via Backend REST API
      try {
        await _apiClient.post(
          ApiEndpoints.sendMessage,
          data: {
            'chatId': chatId,
            'content': content,
            if (parentMessageId != null) 'parentMessageId': parentMessageId,
          },
        );
      } catch (apiErr) {
        print('[SupabaseChatRepository] sendMessage REST API error, writing to Supabase: $apiErr');
      }

      // 2. Insert into Supabase table to ensure real-time stream sync across connected clients
      final now = DateTime.now();
      final messageData = {
        'chat_id': chatId,
        'appointment_id': appointmentId,
        'sender_id': senderId,
        'sender_role': senderRole,
        'content': content,
        'image_url': imageUrl,
        'created_at': now.toIso8601String(),
      };

      await _supabase.from('messages').insert(messageData);

      // 3. Update chat room last message & unread count
      final chatRow = await _supabase
          .from('chats')
          .select()
          .eq('id', chatId)
          .maybeSingle();

      int partnerUnread = chatRow?['partner_unread_count'] as int? ?? 0;
      int patientUnread = chatRow?['patient_unread_count'] as int? ?? 0;

      if (senderRole == 'patient') {
        partnerUnread += 1;
      } else {
        patientUnread += 1;
      }

      await _supabase.from('chats').update({
        'last_message': content,
        'last_message_time': now.toIso8601String(),
        'partner_unread_count': partnerUnread,
        'patient_unread_count': patientUnread,
      }).eq('id', chatId);
    } catch (e) {
      print('[SupabaseChatRepository] sendMessage error: $e');
      rethrow;
    }
  }

  /// Marks partner unread messages as read
  Future<void> markPartnerUnreadAsRead(String chatId) async {
    try {
      await _supabase
          .from('chats')
          .update({'partner_unread_count': 0})
          .eq('id', chatId);
    } catch (e) {
      print('[SupabaseChatRepository] markPartnerUnreadAsRead error: $e');
    }
  }
}
