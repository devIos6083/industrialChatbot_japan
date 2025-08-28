import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/provider/chat_service.dart';

// 메시지 모델 클래스
class Message {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final List<Reference>? references;

  Message({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.references,
  });
}

// 채팅 상태 클래스
class ChatState {
  final List<Message> messages;
  final bool showAttachmentOptions;
  final bool isLoading;
  final String? error;
  final bool isServerConnected;

  ChatState({
    required this.messages,
    this.showAttachmentOptions = false,
    this.isLoading = false,
    this.error,
    this.isServerConnected = true,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? showAttachmentOptions,
    bool? isLoading,
    String? error,
    bool? isServerConnected,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      showAttachmentOptions:
          showAttachmentOptions ?? this.showAttachmentOptions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isServerConnected: isServerConnected ?? this.isServerConnected,
    );
  }
}

// 채팅 상태 관리 StateNotifier
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState(messages: [])) {
    _loadInitialMessages();
    _checkServerConnection();
  }

  // 서버 연결 상태 확인
  Future<void> _checkServerConnection() async {
    try {
      final isConnected = await ChatService.checkServerHealth();
      state = state.copyWith(isServerConnected: isConnected);

      if (!isConnected) {
        _addSystemMessage("⚠️ 서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.");
      }
    } catch (e) {
      state = state.copyWith(isServerConnected: false);
      _addSystemMessage("⚠️ 서버 연결 확인 중 오류가 발생했습니다.");
    }
  }

  // 시스템 메시지 추가 헬퍼 메서드
  void _addSystemMessage(String text) {
    final systemMessage = Message(
      text: text,
      isMe: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, systemMessage],
    );
  }

  // 초기 메시지 로드
  void _loadInitialMessages() {
    final initialMessages = [
      Message(
        text:
            "안녕하세요! KOSHA 가이드 챗봇입니다. 산업안전보건 관련 궁금하신 점을 물어보세요.\n\n예시 질문:\n• 안전모 착용 기준은?\n• 작업장 안전 점검 주기는?\n• 화재 예방 수칙은?",
        isMe: false,
        timestamp: DateTime.now(),
      ),
    ];

    state = state.copyWith(messages: initialMessages);
  }

  // 응답이 관련 없는 내용인지 판단하는 메서드
  bool _isIrrelevantResponse(String response) {
    // "죄송합니다"로 시작하는 패턴들
    final apologeticPatterns = [
      '죄송합니다',
      '죄송하지만',
      '미안합니다',
      '죄송해요',
      '정보를 찾을 수 없습니다',
      '해당 내용에 대해서는',
      '관련 정보가 없습니다',
      '답변하기 어렵습니다',
      '도움을 드릴 수 없습니다',
      '찾을 수 없어',
      '제공할 수 없습니다',
    ];

    // 응답 텍스트를 소문자로 변환하여 체크
    final lowerResponse = response.toLowerCase();

    return apologeticPatterns
        .any((pattern) => lowerResponse.contains(pattern.toLowerCase()));
  }

  // 메시지 보내기 및 실제 API 호출
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 서버 연결 상태 먼저 확인
    if (!state.isServerConnected) {
      await _checkServerConnection();
      if (!state.isServerConnected) {
        _addSystemMessage("서버에 연결할 수 없습니다. 잠시 후 다시 시도해주세요.");
        return;
      }
    }

    // 사용자 메시지 추가
    final userMessage = Message(
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // 실제 API 호출
      final response = await ChatService.sendMessage(text);

      // 응답이 관련 없는 내용인지 확인
      final isIrrelevant = _isIrrelevantResponse(response.answer);

      // 봇 응답 메시지 생성
      final botMessage = Message(
        text: response.answer,
        isMe: false,
        timestamp: DateTime.now(),
        // 관련 없는 응답이면 참고자료를 null로 설정
        references: isIrrelevant ? null : response.references,
      );

      state = state.copyWith(
        messages: [...state.messages, botMessage],
        isLoading: false,
        isServerConnected: true,
      );
    } catch (e) {
      print('채팅 오류: $e');

      // 구체적인 오류 메시지
      String errorText;
      if (e.toString().contains('인터넷 연결')) {
        errorText = "인터넷 연결을 확인해주세요. Wi-Fi 또는 모바일 데이터 상태를 점검해보세요.";
      } else if (e.toString().contains('시간이 초과')) {
        errorText = "요청 시간이 초과되었습니다. 네트워크가 불안정할 수 있습니다. 다시 시도해주세요.";
      } else if (e.toString().contains('서버')) {
        errorText = "서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.";
      } else {
        errorText = "죄송합니다. 요청을 처리하는 중 오류가 발생했습니다. 다시 시도해주세요.";
      }

      final errorMessage = Message(
        text: errorText,
        isMe: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
        error: e.toString(),
        isServerConnected: false,
      );
    }
  }

  // 연결 재시도
  Future<void> retryConnection() async {
    state = state.copyWith(isLoading: true);
    await _checkServerConnection();
    state = state.copyWith(isLoading: false);

    if (state.isServerConnected) {
      _addSystemMessage("✅ 서버 연결이 복구되었습니다!");
    }
  }

  // 첨부 옵션 표시/숨김 토글
  void toggleAttachmentOptions() {
    state = state.copyWith(showAttachmentOptions: !state.showAttachmentOptions);
  }

  // 에러 상태 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }

  // 채팅 기록 삭제
  void clearMessages() {
    state = state.copyWith(messages: []);
    _loadInitialMessages();
  }
}

// 채팅 Provider 정의
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
