import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import thư viện này để hiển thị text AI đẹp
import '../../services/chat_ai_service.dart'; // Import Service AI

// Model tin nhắn
class ChatMessage {
  final String text;
  final bool isUser; // true: Mình, false: Bobo
  final String time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // 1. Gọi Service AI
  final ChatAiService _chatService = ChatAiService();
  bool _isLoading = false; // Biến để hiện trạng thái "Đang soạn tin..."

  // Dữ liệu mẫu ban đầu
  final List<ChatMessage> _messages = [
    ChatMessage(text: "Hi Bobo! 🤖", isUser: true, time: "09:41"),
    ChatMessage(text: "Hello! 👋 Tui là trợ lý ảo Smartify đây. Tui giúp gì được cho bạn nè?", isUser: false, time: "09:41"),
  ];

  // Hàm gửi tin nhắn
  void _sendMessage() async {
    String userText = _textController.text.trim();
    if (userText.isEmpty) return;

    // 1. Hiện tin nhắn của User ngay lập tức
    setState(() {
      _messages.add(ChatMessage(
        text: userText,
        isUser: true,
        time: _getCurrentTime(),
      ));
      _isLoading = true; // Bật chế độ đang gõ
    });
    
    _textController.clear();
    _scrollToBottom();

    // 2. Gọi API Gemini (AI trả lời)
    String aiResponse = await _chatService.sendMessage(userText);

    // 3. Cập nhật giao diện khi có câu trả lời
    if (mounted) {
      setState(() {
        _isLoading = false; // Tắt chế độ đang gõ
        _messages.add(ChatMessage(
          text: aiResponse,
          isUser: false,
          time: _getCurrentTime(),
        ));
      });
      _scrollToBottom();
    }
  }

  // Hàm lấy giờ hiện tại (VD: 10:30)
  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Chat with Bobo",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // DANH SÁCH TIN NHẮN
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isLoading ? 1 : 0), // Cộng thêm 1 nếu đang load
              itemBuilder: (context, index) {
                // Nếu đang ở item cuối cùng và đang loading -> Hiện cục "Đang gõ..."
                if (_isLoading && index == _messages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Bobo is typing...", 
                        style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 12),
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                return _buildMessageBubble(msg, primaryColor);
              },
            ),
          ),

          // KHUNG NHẬP LIỆU (Input Area)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                // Text Field
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: "Ask me anything ...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Send Button
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, Color primaryColor) {
    // Nếu là Bobo thì hiện Avatar
    if (!msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Bobo (Dùng Icon thay thế nếu chưa có ảnh)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(
                  'assets/images/robot_avatar.png', // Vợ nhớ chép ảnh robot vào đây nha
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.smart_toy, color: Colors.blueAccent),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Bong bóng chat Bobo (Dùng Markdown)
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    // SỬ DỤNG MARKDOWN BODY CHO AI
                    child: MarkdownBody(
                      data: msg.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(msg.time, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 40), // Khoảng trống bên phải
          ],
        ),
      );
    } else {
      // Tin nhắn của User (Màu xanh) - Giữ nguyên Text thường
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 40), // Khoảng trống bên trái
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))
                      ]
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(msg.time, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}