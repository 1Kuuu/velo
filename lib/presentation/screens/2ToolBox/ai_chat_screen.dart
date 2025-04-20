import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/presentation/screens/2ToolBox/gemini_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _userBikeType;
  final ScrollController _scrollController = ScrollController();
  final _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _loadUserBikeType();
    // Add a welcome message
    _messages.add(ChatMessage(
      text: "Hello! I'm your AI assistant. What would you like to know?",
      isUser: false,
    ));
  }

  Future<void> _loadUserBikeType() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('user_preferences')
            .doc(user.uid)
            .get();
        
        setState(() {
          _userBikeType = doc.data()?['bike_type']?.toLowerCase();
        });
      }
    } catch (e) {
      print('Error loading bike type: $e');
    }
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
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isUser: true,
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Create a bike-specific prompt if we have the user's bike type
      String prompt = messageText;
      if (_userBikeType != null) {
        prompt = '''You are a knowledgeable AI assistant with extensive expertise in cycling, bike maintenance, and general knowledge.
        
The user owns a $_userBikeType. When discussing cycling topics, provide specific advice for this bike type when relevant.

When answering questions about bikes and cycling:
1. Provide detailed, bike-specific advice when applicable
2. Include step-by-step instructions for maintenance and repairs
3. Mention safety considerations and best practices
4. Suggest tools and equipment needed
5. Explain technical terms in simple language
6. Include relevant measurements and specifications
7. Mention common mistakes to avoid
8. Provide troubleshooting tips
9. Share riding techniques and tips
10. Discuss bike parts and their functions
11. Explain maintenance schedules
12. Provide gear recommendations
13. Share route planning advice
14. Discuss bike fitting and adjustments
15. Explain bike technology and innovations

When answering non-cycling questions:
1. Provide accurate, well-researched information
2. Explain complex topics in simple terms
3. Include relevant examples and analogies
4. Cite sources when appropriate
5. Acknowledge limitations or uncertainties
6. Offer different perspectives when relevant
7. Suggest related topics for further learning

General guidelines for all responses:
1. Be clear and concise
2. Use appropriate technical depth
3. Maintain a helpful and friendly tone
4. Acknowledge when you're unsure
5. Suggest follow-up questions
6. Break down complex topics into digestible parts
7. Use analogies to explain difficult concepts
8. Provide real-world examples
9. Include safety warnings when relevant
10. Suggest additional resources when helpful

User question: $messageText''';
      }

      // Use the GeminiService to get the response
      final response = await _geminiService.getResponse(prompt);

      // Log the response to the console for debugging
      print("Received response: $response");

      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
        ));
        _scrollToBottom();
      });
    } catch (e) {
      print('Error getting AI response: $e');
      setState(() {
        _messages.add(ChatMessage(
          text: "Sorry, I couldn't process your request. Please try again later.",
          isUser: false,
        ));
        _scrollToBottom();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: MyAppBar(
        title: 'Ask AI',
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'About AI Chat',
                    style: AppFonts.bold.copyWith(
                      fontSize: 20,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  content: Text(
                    'This feature allows you to chat with an AI assistant about any topic, with special expertise in bikes and cycling.',
                    style: AppFonts.regular.copyWith(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: AppFonts.medium.copyWith(
                          color: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Send a message to start the conversation',
                      style: AppFonts.regular.copyWith(
                        color: isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? (isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary)
                                : (isDarkMode
                                    ? const Color(0xFF2D2D2D)
                                    : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.text,
                            style: AppFonts.regular.copyWith(
                              fontSize: 16,
                              color: message.isUser
                                  ? Colors.white
                                  : (isDarkMode
                                      ? Colors.white70
                                      : Colors.black87),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Thinking...',
                    style: AppFonts.medium.copyWith(
                      color: isDarkMode ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: AppFonts.regular.copyWith(
                      fontSize: 16,
                      color: isDarkMode
                          ? Colors.white70
                          : Colors.black87,
                    ),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Ask anything...',
                      hintStyle: AppFonts.regular.copyWith(
                        fontSize: 16,
                        color: isDarkMode
                            ? Colors.white60
                            : Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.grey[100],
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
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
