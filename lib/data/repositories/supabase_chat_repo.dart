import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/chat_room_model.dart';
import 'app_config_repo.dart';

class SupabaseChatRepository {
  final SupabaseClient? _client;
  final AppConfigRepository _appConfigRepo;

  SupabaseChatRepository({
    SupabaseClient? client,
    required AppConfigRepository appConfigRepo,
  })  : _client = client,
        _appConfigRepo = appConfigRepo;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

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
      // 1. Check if chat already exists
      final existingChat = await _supabase
          .from('chats')
          .select()
          .eq('patient_id', patientId)
          .eq('partner_id', partnerId)
          .maybeSingle();

      if (existingChat != null) {
        return ChatRoomModel.fromJson(existingChat);
      }

      // 2. Insert new chat room if not existing
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

  /// Streams real-time messages for a specific chat room (chatId)
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

  /// Streams active chat rooms for a pharmacy partner for the ChatsListScreen
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

  /// Sends a chat message and updates the parent chat room metadata (last message, unread count).
  /// Respects role-based message limits configured via AppConfigRepository if any are active.
  Future<void> sendMessage({
    required String chatId,
    required String appointmentId,
    required String senderId,
    required String senderRole, // 'patient' or 'partner'
    required String content,
    String? imageUrl,
  }) async {
    try {
      // 1. Evaluate message limits if active
      if (senderRole == 'patient') {
        final limit = await _appConfigRepo.getPatientMessageLimit();
        if (limit != null && limit > 0) {
          final countRes = await _supabase
              .from('messages')
              .select('id')
              .eq('appointment_id', appointmentId)
              .eq('sender_role', 'patient');
          final currentCount = (countRes as List).length;
          if (currentCount >= limit) {
            throw Exception('Patient message limit of $limit reached for this appointment.');
          }
        }
      } else if (senderRole == 'partner') {
        final limit = await _appConfigRepo.getPartnerMessageLimit();
        if (limit != null && limit > 0) {
          final countRes = await _supabase
              .from('messages')
              .select('id')
              .eq('appointment_id', appointmentId)
              .eq('sender_role', 'partner');
          final currentCount = (countRes as List).length;
          if (currentCount >= limit) {
            throw Exception('Partner message limit of $limit reached for this appointment.');
          }
        }
      }

      final now = DateTime.now();

      // 2. Insert message into messages table
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

      // 3. Fetch current chat room to update unread count
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

  /// Marks partner unread messages as read (resets partner_unread_count to 0)
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
