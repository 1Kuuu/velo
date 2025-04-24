import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String? focusedCommentId;

  const PostDetailScreen({
    Key? key,
    required this.postId,
    this.focusedCommentId,
  }) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _postData;
  List<Map<String, dynamic>> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPostAndComments();
  }

  Future<void> _loadPostAndComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load post data
      final postDoc = await _firestore.collection('posts').doc(widget.postId).get();
      
      if (!postDoc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get post data
      final postData = postDoc.data() as Map<String, dynamic>;
      
      // Get user info
      final userDoc = await _firestore
          .collection('users')
          .doc(postData['userId'])
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        postData['userName'] = userData['userName'] ?? 'User';
        postData['userProfileUrl'] = userData['profileUrl'];
      }

      // Load comments
      final commentsQuery = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: widget.postId)
          .orderBy('timestamp', descending: false)
          .get();

      final List<Map<String, dynamic>> comments = [];
      
      for (var doc in commentsQuery.docs) {
        final commentData = doc.data();
        commentData['id'] = doc.id;
        
        // Get comment user info
        final commentUserDoc = await _firestore
            .collection('users')
            .doc(commentData['userId'])
            .get();
        
        if (commentUserDoc.exists) {
          final commentUserData = commentUserDoc.data() as Map<String, dynamic>;
          commentData['userName'] = commentUserData['userName'] ?? 'User';
          commentData['userProfileUrl'] = commentUserData['profileUrl'];
        }
        
        comments.add(commentData);
      }

      setState(() {
        _postData = postData;
        _comments = comments;
        _isLoading = false;
      });
      
      // Scroll to focused comment if specified
      if (widget.focusedCommentId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToComment(widget.focusedCommentId!);
        });
      }
    } catch (e) {
      print('Error loading post: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToComment(String commentId) {
    // This would be implemented with a ScrollController in a real app
    print('Should scroll to comment: $commentId');
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Add comment to Firestore
      await _firestore.collection('comments').add({
        'postId': widget.postId,
        'userId': userId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update post comment count
      await _firestore.collection('posts').doc(widget.postId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Create notification for post owner
      if (_postData != null && _postData!['userId'] != userId) {
        await _firestore.collection('notifications').add({
          'type': 'comment',
          'senderId': userId,
          'recipientId': _postData!['userId'],
          'message': 'commented on your post',
          'postId': widget.postId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      // Clear input and refresh comments
      _commentController.clear();
      await _loadPostAndComments();
    } catch (e) {
      print('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text('Post Details'),
        backgroundColor: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _postData == null
              ? Center(child: Text('Post not found'))
              : Column(
                  children: [
                    // Post content (scrollable area)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Post content
                            _buildPostContent(),
                            
                            // Comments section
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Comments (${_comments.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            
                            // Comments list
                            ..._comments.map((comment) => _buildCommentItem(comment)).toList(),
                            
                            // Add some bottom padding
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    
                    // Comment input box
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                        border: Border(
                          top: BorderSide(
                            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send),
                            color: isDarkMode 
                                ? const Color(0xFF4A3B7C) 
                                : AppColors.primary,
                            onPressed: _addComment,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPostContent() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final userName = _postData!['userName'] ?? 'User';
    final userProfileUrl = _postData!['userProfileUrl'];
    final timestamp = (_postData!['timestamp'] as Timestamp).toDate();
    final content = _postData!['content'] ?? '';
    final imageUrl = _postData!['imageUrl'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and timestamp
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: ChatUtils.generateRandomColor(userName),
                backgroundImage: userProfileUrl != null 
                    ? NetworkImage(userProfileUrl) 
                    : null,
                child: userProfileUrl == null 
                    ? Text(
                        ChatUtils.getInitials(userName),
                        style: TextStyle(color: Colors.white),
                      ) 
                    : null,
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Post content
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          
          // Post image if exists
          if (imageUrl != null)
            Container(
              height: 200,
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          // Post stats (likes, comments)
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: Colors.red,
                size: 18,
              ),
              SizedBox(width: 4),
              Text(
                '${_postData!['likeCount'] ?? 0}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
              ),
              SizedBox(width: 16),
              Icon(
                Icons.comment,
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
                size: 18,
              ),
              SizedBox(width: 4),
              Text(
                '${_postData!['commentCount'] ?? 0}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ],
          ),
          
          Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final userName = comment['userName'] ?? 'User';
    final userProfileUrl = comment['userProfileUrl'];
    final timestamp = (comment['timestamp'] as Timestamp).toDate();
    final text = comment['text'] ?? '';
    final isFocused = widget.focusedCommentId == comment['id'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isFocused 
            ? (isDarkMode ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05))
            : null,
        border: isFocused
            ? Border.all(
                color: isDarkMode ? Colors.blue[800]! : Colors.blue[300]!,
                width: 1,
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: ChatUtils.generateRandomColor(userName),
            backgroundImage: userProfileUrl != null 
                ? NetworkImage(userProfileUrl) 
                : null,
            child: userProfileUrl == null 
                ? Text(
                    ChatUtils.getInitials(userName),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ) 
                : null,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 