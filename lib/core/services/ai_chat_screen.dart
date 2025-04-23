import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/core/services/gemini_service.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;
  bool _isError = false;
  final ScrollController _scrollController = ScrollController();
  final List<String> _suggestedQuestions = [
    "How do I maintain my bike chain?",
    "What's the proper tire pressure for road biking?",
    "How do I adjust my bike seat height?",
    "What safety gear do I need for cycling?",
    "How often should I service my bike?",
    "What's the best way to clean my bike?",
  ];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: "Hello! I'm your cycling AI assistant. I can help you with:\n\n"
          "• Bike maintenance and repair\n"
          "• Cycling techniques and best practices\n"
          "• Bike components and their functions\n"
          "• Safety guidelines and equipment\n"
          "• Training and performance tips\n"
          "• Bike selection and fitting\n\n"
          "What would you like to know about?",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
      ));
      _isLoading = true;
      _isError = false;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _geminiService.sendMessage(userMessage);
      
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _messages.add(ChatMessage(
            text: "I apologize, but I encountered an error. Please try asking your question again.",
            isUser: false,
          ));
        });
        _scrollToBottom();
      }
    }
  }

  void _retryLastMessage() {
    if (_messages.isEmpty) return;
    
    // Find the last user message
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        final lastUserMessage = _messages[i].text;
        // Remove all messages after this one
        setState(() {
          _messages.removeRange(i, _messages.length);
          _isError = false;
        });
        // Resend the message
        _messageController.text = lastUserMessage;
        _sendMessage();
        break;
      }
    }
  }

  void _resetChat() {
    setState(() {
      _messages.clear();
      _isError = false;
      _isLoading = false;
    });
    _geminiService.resetChat();
    _addWelcomeMessage();
  }

  void _useSuggestedQuestion(String question) {
    _messageController.text = question;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground,
      appBar: MyAppBar(
        title: 'Cycling Assistant',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            onPressed: _resetChat,
          ),
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggested Questions:',
                    style: AppFonts.medium.copyWith(
                      fontSize: 18,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestedQuestions.map((question) {
                      return ActionChip(
                        label: Text(question),
                        onPressed: () => _useSuggestedQuestion(question),
                        backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[200],
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pedal_bike,
                          size: 64,
                          color: isDarkMode ? Colors.white38 : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ask me anything about cycling!',
                          style: AppFonts.medium.copyWith(
                            fontSize: 18,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ChatBubble(
                        message: message,
                        isDarkMode: isDarkMode,
                      );
                    },
                  ),
          ),
          if (_isError)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _retryLastMessage,
                    child: Text(
                      'Tap to retry',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thinking...',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask about cycling...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  backgroundColor: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
                  child: Icon(
                    Icons.send,
                    color: _isLoading ? Colors.grey : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDarkMode;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser
              ? (isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary)
              : (isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message.text,
          style: AppFonts.regular.copyWith(
            color: message.isUser
                ? Colors.white
                : (isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }
} 