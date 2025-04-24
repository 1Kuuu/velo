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
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;
  bool _isError = false;
  bool _showSuggestions = false;
  List<String> _currentSuggestions = [];
  final ScrollController _scrollController = ScrollController();
  
  // Fixed list of suggestions for quick access
  final List<String> _quickSuggestions = [
    "How do I clean and lube my bike chain?",
    "What's the proper tire pressure for my mountain bike?",
    "How to fix a flat tire on the road?",
    "What's the proper cycling posture?",
    "How can I climb hills more efficiently?",
    "How to improve my cycling endurance?",
    "What cycling gear do I need as a beginner?",
    "How to choose the right bike helmet?",
    "How to find good cycling routes near me?",
  ];
  
  final List<Map<String, dynamic>> _suggestedQuestions = [
    {
      "category": "Maintenance",
      "questions": [
        "How do I clean and lube my bike chain?",
        "What's the proper tire pressure for my mountain bike?",
        "How often should I tune up my bike?",
        "How to fix squeaky disc brakes?",
        "How to fix a flat tire on the road?",
      ]
    },
    {
      "category": "Technique",
      "questions": [
        "What's the proper cycling posture?",
        "How can I climb hills more efficiently?",
        "How to improve my cycling endurance?",
        "What's a good cadence for road cycling?",
        "How to bike in rainy conditions safely?",
      ]
    },
    {
      "category": "Gear",
      "questions": [
        "What cycling gear do I need as a beginner?",
        "How to choose the right bike helmet?",
        "Are carbon fiber frames worth it?",
        "What cycling shoes should I get?",
        "Best bike lights for night riding?",
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _focusNode.addListener(_onFocusChange);
    _refreshSuggestions();
  }

  void _refreshSuggestions() {
    debugPrint("Refreshing suggestions");
    
    // Show 3 random suggestions
    setState(() {
      _currentSuggestions = [];
      List<String> tempList = List.from(_quickSuggestions);
      tempList.shuffle();
      
      for (int i = 0; i < 3; i++) {
        _currentSuggestions.add(tempList[i]);
      }
      
      _showSuggestions = true;
    });
    debugPrint("New suggestions: $_currentSuggestions");
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _messageController.text.isEmpty) {
      if (!_showSuggestions) {
        _refreshSuggestions();
      }
    } else {
      setState(() {
        _showSuggestions = false;
      });
    }
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
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
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

  void _handleSuggestionTap(dynamic question) {
    String questionText = question.toString();
    debugPrint("Suggestion tapped: $questionText");
    _messageController.text = questionText;
    
    // Close suggestions immediately
    setState(() {
      _showSuggestions = false;
    });
    
    // Use a delayed microtask to ensure UI updates first
    Future.microtask(() {
      _sendMessage();
    });
  }

  // Remove asterisks from text
  String _removeAsterisks(String text) {
    return text.replaceAll('*', '');
  }

  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    debugPrint("Sending message: $userMessage");
    setState(() {
      _showSuggestions = false;
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
        final cleanedResponse = _removeAsterisks(response);
        setState(() {
          _messages.add(ChatMessage(
            text: cleanedResponse,
            isUser: false,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
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
      _showSuggestions = false;
    });
    _geminiService.resetChat();
    _addWelcomeMessage();
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
          Expanded(
            child: _messages.isEmpty
                ? _buildSuggestedQuestionsUI(isDarkMode)
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
                    style: AppFonts.regular.copyWith(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          _buildInputSection(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildInputSection(bool isDarkMode) {
    return Column(
      children: [
        if (_showSuggestions && _currentSuggestions.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Text(
                        'Suggested Questions',
                        style: AppFonts.medium.copyWith(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _refreshSuggestions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                ..._currentSuggestions.map((suggestion) => 
                  GestureDetector(
                    onTap: () => _handleSuggestionTap(suggestion),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black12 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        suggestion,
                        style: AppFonts.regular.copyWith(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  )
                ).toList(),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Ask about cycling...',
                    hintStyle: AppFonts.regular.copyWith(
                      color: isDarkMode ? Colors.white60 : Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
                  ),
                  style: AppFonts.regular.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  onChanged: (value) {
                    if (_showSuggestions && value.isNotEmpty) {
                      setState(() {
                        _showSuggestions = false;
                      });
                    } else if (!_showSuggestions && value.isEmpty) {
                      _refreshSuggestions();
                    }
                  },
                  onTap: () {
                    if (_messageController.text.isEmpty && !_showSuggestions) {
                      _refreshSuggestions();
                    }
                  },
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(8),
                  disabledBackgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[400],
                ),
                child: Icon(
                  Icons.send,
                  color: _isLoading ? Colors.grey[400] : Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedQuestionsUI(bool isDarkMode) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
            ..._suggestedQuestions.map((category) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      category['category']! as String,
                      style: AppFonts.bold.copyWith(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (category['questions'] as List<dynamic>).map((question) {
                      return GestureDetector(
                        onTap: () => _handleSuggestionTap(question),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            question as String,
                            style: AppFonts.regular.copyWith(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ],
        ),
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
    // Get the display text, removing asterisks if it's from the AI
    final displayText = message.isUser ? message.text : message.text.replaceAll('*', '');
    
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
          displayText,
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