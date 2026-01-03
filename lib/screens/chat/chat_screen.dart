import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

// Model tin nhắn
class ChatMessage {
  final String text;
  final bool isUser;
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
  
  // Dữ liệu tin nhắn
  final List<ChatMessage> _messages = [];
  
  // WebSocket Client
  StompClient? _stompClient;
  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    // Tin nhắn chào mặc định
    _messages.add(ChatMessage(text: "Hi Bobo! 🤖", isUser: true, time: _getCurrentTime()));
    _messages.add(ChatMessage(text: "Hello! 👋 Tui là trợ lý ảo Smartify đây. Tui giúp gì được cho bạn nè?", isUser: false, time: _getCurrentTime()));
  }

  // --- LOGIC WEBSOCKET ---
  void _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId')?.toString() ?? "guest";
    });
    _initWebSocket();
  }

  void _initWebSocket() {
    if (_userId == null) return;

    _stompClient = StompClient(
      config: StompConfig(
        url: AppConfig.webSocketUrl, 
        onConnect: (frame) {
          // Lắng nghe câu trả lời từ AI
          _stompClient!.subscribe(
            destination: '/topic/chat/$_userId', 
            callback: (frame) {
              if (frame.body != null) {
                final data = jsonDecode(frame.body!);
                _receiveAiMessage(data['text']);
              }
            },
          );
        },
        onStompError: (frame) => print("❌ Lỗi Chat Socket: ${frame.body}"),
        webSocketConnectHeaders: {"transports": ["websocket"]},
      ),
    );
    _stompClient!.activate();
  }

  void _sendMessage() {
    String text = _textController.text.trim();
    if (text.isEmpty) return;

    // 1. Hiện tin nhắn của mình ngay
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, time: _getCurrentTime()));
      _isLoading = true; 
    });
    _textController.clear();
    _scrollToBottom();

    // 2. Gửi qua WebSocket
    if (_stompClient != null && _stompClient!.connected) {
      _stompClient!.send(
        destination: '/app/chat.sendMessage',
        body: jsonEncode({
          "userId": _userId,
          "message": text,
          "action": "CHAT"
        }),
      );
    } else {
      // Fallback nếu mất mạng
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _messages.add(ChatMessage(text: "⚠️ Mất kết nối máy chủ. Vui lòng thử lại!", isUser: false, time: _getCurrentTime()));
          });
          _scrollToBottom();
        }
      });
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(text: "Đã xóa ký ức! Bắt đầu lại nào. 🚀", isUser: false, time: _getCurrentTime()));
    });

    if (_stompClient != null && _stompClient!.connected) {
      _stompClient!.send(
        destination: '/app/chat.sendMessage',
        body: jsonEncode({
          "userId": _userId,
          "message": "",
          "action": "CLEAR"
        }),
      );
    }
  }

  void _receiveAiMessage(String text) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(text: text, isUser: false, time: _getCurrentTime()));
      });
      _scrollToBottom();
    }
  }

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
  void dispose() {
    _stompClient?.deactivate();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- PHẦN GIAO DIỆN (GIỮ NGUYÊN CỦA VỢ) ---
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
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: "Xóa đoạn chat",
            onPressed: _clearChat,
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
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
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

          // KHUNG NHẬP LIỆU
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
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
    if (!msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.smart_toy, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(width: 12),
            
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
            const SizedBox(width: 40), 
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 40), 
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