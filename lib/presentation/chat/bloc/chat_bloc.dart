import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/chat_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  String? _currentRequestId;

  // Local stateful message cache for simulation
  final List<ChatMessage> _mockMessages = [];
  Timer? _simulatedReplyTimer;

  ChatBloc() : super(ChatInitial()) {
    on<LoadChatHistory>(_onLoadChatHistory);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistory event,
    Emitter<ChatState> emit,
  ) async {
    _currentRequestId = event.requestId;
    emit(ChatLoading());

    // Initialize mock messages for the request session
    _mockMessages.clear();
    _mockMessages.addAll([
      ChatMessage(
        id: 'msg-1',
        senderId: 'patient-123',
        senderRole: 'patient',
        content: 'Hi Dr., thank you for accepting my request. I am experiencing moderate knee swelling.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
        id: 'msg-2',
        senderId: 'partner-456',
        senderRole: 'partner',
        content: 'Hello, I see your request. Have you applied ice to the area yet?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      ChatMessage(
        id: 'msg-3',
        senderId: 'patient-123',
        senderRole: 'patient',
        content: 'Yes, I did, but it still hurts when I bend it. I uploaded my report.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ]);

    // Delay for UI realism
    await Future.delayed(const Duration(milliseconds: 300));
    emit(ChatLoaded(List<ChatMessage>.from(_mockMessages)));
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded || _currentRequestId == null) return;

    final newMessage = ChatMessage(
      id: 'msg-partner-${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'partner-id',
      senderRole: 'partner',
      content: event.content,
      imageUrl: event.imageUrl,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<ChatMessage>.from(currentState.messages)..add(newMessage);
    emit(ChatLoaded(updatedMessages));

    // Local simulation: trigger automatic patient response after 2 seconds
    _simulatedReplyTimer?.cancel();
    _simulatedReplyTimer = Timer(const Duration(seconds: 2), () {
      if (state is ChatLoaded && !isClosed) {
        final reply = ChatMessage(
          id: 'msg-patient-reply-${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'patient-id',
          senderRole: 'patient',
          content: _getSimulatedResponse(event.content),
          timestamp: DateTime.now(),
        );
        add(MessageReceived(reply));
      }
    });
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final exists = currentState.messages.any((m) => m.id == event.message.id);
      if (!exists) {
        final updated = List<ChatMessage>.from(currentState.messages)..add(event.message);
        emit(ChatLoaded(updated));
      }
    }
  }

  String _getSimulatedResponse(String partnerText) {
    final lower = partnerText.toLowerCase();
    if (lower.contains('ice') || lower.contains('cold')) {
      return 'I will keep applying ice for 20 minutes as you recommended. Should I take any painkillers?';
    } else if (lower.contains('pain') || lower.contains('hurt')) {
      return 'It hurts mostly when I try to stand up or apply weight. The swelling has not gone down.';
    } else if (lower.contains('hello') || lower.contains('hi')) {
      return 'Hello Doctor! Thanks for the prompt reply.';
    } else if (lower.contains('xray') || lower.contains('scan') || lower.contains('mri') || lower.contains('report')) {
      return 'I have uploaded the scan report PDF in the attachments section. Please let me know what you think.';
    } else {
      return 'Okay, thank you, Doctor. Let me know what the next steps are.';
    }
  }

  @override
  Future<void> close() {
    _simulatedReplyTimer?.cancel();
    return super.close();
  }
}
