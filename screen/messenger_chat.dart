// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/provider/chat_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class MessengerChatScreenRiverpod extends ConsumerWidget {
  const MessengerChatScreenRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 채팅 상태 구독
    final chatState = ref.watch(chatProvider);
    // TextEditingController 생성
    final TextEditingController messageController = TextEditingController();

    // 메시지 전송 함수
    void sendMessage() {
      if (messageController.text.trim().isNotEmpty) {
        ref.read(chatProvider.notifier).sendMessage(messageController.text);
        messageController.clear();
      }
    }

    // 첨부 옵션 토글 함수
    void toggleAttachmentOptions() {
      ref.read(chatProvider.notifier).toggleAttachmentOptions();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey[200],
                radius: 20,
                child: ClipOval(
                  child: Image.asset(
                    'img/chat_bot.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KOSHA 챗봇',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '산업안전보건 가이드 도우미',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 채팅 메시지 영역
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message =
                    chatState.messages[chatState.messages.length - 1 - index];
                final previousMessage = index < chatState.messages.length - 1
                    ? chatState.messages[chatState.messages.length - index - 2]
                    : null;

                return _buildMessageBubble(message, previousMessage);
              },
            ),
          ),

          // 로딩 인디케이터
          if (chatState.isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '응답을 기다리는 중...',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

          // 에러 메시지
          if (chatState.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red[50],
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '오류가 발생했습니다. 다시 시도해주세요.',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(chatProvider.notifier).clearError();
                    },
                  ),
                ],
              ),
            ),

          // 첨부 옵션 영역
          if (chatState.showAttachmentOptions)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                      Icons.camera_alt, "카메라", Colors.purple),
                  _buildAttachmentOption(
                      Icons.photo_library, "앨범", Colors.green),
                  _buildAttachmentOption(Icons.mic, "마이크", Colors.orange),
                ],
              ),
            ),

          // 메시지 입력 영역
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    chatState.showAttachmentOptions
                        ? Icons.close
                        : Icons.chevron_right,
                    color: Colors.blue,
                  ),
                  onPressed: toggleAttachmentOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "메시지를 입력하세요...",
                      hintStyle: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => sendMessage(),
                    enabled: !chatState.isLoading,
                  ),
                ),
                IconButton(
                  onPressed: chatState.isLoading ? null : sendMessage,
                  icon: Icon(
                    Icons.send_outlined,
                    color:
                        chatState.isLoading ? Colors.grey : Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: color,
          radius: 24,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message, Message? previousMessage) {
    bool isDifferentSender =
        previousMessage == null || previousMessage.isMe != message.isMe;

    return Column(
      crossAxisAlignment:
          message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (isDifferentSender)
          const SizedBox(height: 16)
        else
          const SizedBox(height: 8),

        Row(
          mainAxisAlignment:
              message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 챗봇 메시지인 경우
            if (!message.isMe) ...[
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                child: ClipOval(
                  child: Image.asset(
                    'img/chat_bot.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // 메시지 말풍선
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: message.isMe ? Colors.blue[400] : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: message.isMe
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                    bottomRight: message.isMe
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: message.isMe ? Colors.white : Colors.black,
                      ),
                    ),

                    // 참고자료가 있는 경우 표시 (죄송합니다로 시작하지 않는 경우만)
                    if (message.references != null &&
                        message.references!.isNotEmpty &&
                        !message.text.startsWith('죄송합니다')) ...[
                      const SizedBox(height: 8),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: message.isMe
                              ? Colors.blue[300]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📚 참고자료',
                              style: GoogleFonts.notoSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: message.isMe
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...message.references!.map((ref) => Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '• ${ref.content.length > 50 ? '${ref.content.substring(0, 50)}...' : ref.content}',
                                    style: GoogleFonts.notoSans(
                                      fontSize: 11,
                                      color: message.isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (message.isMe) const SizedBox(width: 8),
          ],
        ),

        // 시간 표시
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _formatTime(message.timestamp),
            style: GoogleFonts.notoSans(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
