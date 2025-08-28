import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // ngrok URL로 업데이트 (현재 활성화된 ngrok URL)
  static String get baseUrl {
    // ngrok 공개 URL 사용
    return "Your_Api_key";
  }

  static Future<ChatApiResponse> sendMessage(String query) async {
    try {
      print('📤 API 요청 시작: $query'); // 디버깅용 로그

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          // ngrok에서 필요할 수 있는 헤더 추가
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'query': query,
        }),
      );

      print('📥 응답 상태코드: ${response.statusCode}'); // 디버깅용 로그

      if (response.statusCode == 200) {
        // UTF-8 디코딩 명시적으로 처리
        final decodedResponse = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = jsonDecode(decodedResponse);

        print('✅ API 응답 성공'); // 디버깅용 로그
        return ChatApiResponse.fromJson(data);
      } else {
        print('❌ 서버 오류: ${response.statusCode} - ${response.body}');
        throw Exception('서버에서 응답을 받을 수 없습니다. (상태코드: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ 네트워크 오류: $e');

      // 구체적인 오류 메시지 제공
      if (e.toString().contains('SocketException')) {
        throw Exception('인터넷 연결을 확인해주세요.');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('요청 시간이 초과되었습니다. 다시 시도해주세요.');
      } else {
        throw Exception('네트워크 오류가 발생했습니다: $e');
      }
    }
  }

  // 서버 상태 확인 메서드 추가
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('서버 상태 확인 실패: $e');
      return false;
    }
  }
}

class ChatApiResponse {
  final String answer;
  final List<Reference> references;

  ChatApiResponse({
    required this.answer,
    required this.references,
  });

  factory ChatApiResponse.fromJson(Map<String, dynamic> json) {
    return ChatApiResponse(
      answer: json['answer'] ?? '',
      references: (json['references'] as List?)
              ?.map((ref) => Reference.fromJson(ref))
              .toList() ??
          [],
    );
  }
}

class Reference {
  final int id;
  final String content;
  final Map<String, dynamic> metadata;

  Reference({
    required this.id,
    required this.content,
    required this.metadata,
  });

  factory Reference.fromJson(Map<String, dynamic> json) {
    return Reference(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}
