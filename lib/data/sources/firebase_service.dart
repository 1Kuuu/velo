import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/data/sources/notification_service.dart';


class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  static const String userCollection = 'user_profile';
  static const String postsCollection = 'posts';
  static const String likesCollection = 'likes';

  /// 🔹 Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// 🔹 Create or Update User Document
  Future<void> createUserDocument({
    required String uid,
    required String username,
    required String email,
    String profileUrl = "",
  }) async {
    try {
      await _firestore.collection(userCollection).doc(uid).set({
        'userName': username,
        'email': email,
        'profileUrl': profileUrl,
        'bio': "",
        'coverUrl': '',
        'activitiesCount': 0,
        'postsCount': 0,
        'likesCount': 0,
        'followers': [],
        'following': [],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Handle error silently
    }
  }

  /// 🔹 Get User Data
  Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      return await _firestore.collection(userCollection).doc(uid).get();
    } catch (e) {
      return null;
    }
  }

  /// 🔹 Update User Data
  Future<void> updateUserData(
      String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(userCollection).doc(uid).update(data);
    } catch (e) {
      // Handle error silently
    }
  }

  /// 🔹 Check if Onboarding is Complete
  Future<bool> isOnboardingComplete() async {
    if (currentUserId == null) return false;
    DocumentSnapshot? userData = await getUserData(currentUserId!);
    return userData?['setupComplete'] ?? false;
  }

  /// 🔹 Mark Onboarding as Complete
  Future<void> completeOnboarding() async {
    if (currentUserId == null) return;
    try {
      await _firestore.collection(userCollection).doc(currentUserId).update({
        'setupComplete': true,
      });
    } catch (e) {
      // Handle error silently
    }
  }

  /// 🔹 Get User Profile
  Future<Map<String, dynamic>> getUserProfile([String? userId]) async {
    try {
      if (_auth.currentUser == null) throw _authException();

      String uid = userId ?? _auth.currentUser!.uid;
      DocumentSnapshot doc =
          await _firestore.collection(userCollection).doc(uid).get();

      if (doc.exists) return doc.data() as Map<String, dynamic>;

      // Create default profile if it doesn't exist
      Map<String, dynamic> defaultData = {
        'userName': 'New User',
        'bio': 'No bio yet',
        'profileUrl': '',
        'coverUrl': '',
        'activitiesCount': 0,
        'postsCount': 0,
        'likesCount': 0,
        'followers': [],
        'following': [],
        'email': _auth.currentUser?.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (uid == _auth.currentUser!.uid) {
        await _firestore
            .collection(userCollection)
            .doc(uid)
            .set(defaultData, SetOptions(merge: true));
      }

      return defaultData;
    } catch (e) {
      return {};
    }
  }

  /// 🔹 Create a New Post
  Future<String?> createPost({
    required String content,
    List<String> images = const [],
    Map<String, dynamic>? activityData,
  }) async {
    try {
      if (_auth.currentUser == null) throw _authException();

      String uid = _auth.currentUser!.uid;
      DocumentSnapshot userDoc =
          await _firestore.collection(userCollection).doc(uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      DocumentReference postRef =
          await _firestore.collection(postsCollection).add({
        'userId': uid,
        'userName': userData['userName'] ?? 'Unknown User',
        'userProfileUrl': userData['profileUrl'] ?? '',
        'content': content,
        'images': images,
        'activityData': activityData,
        'likesCount': 0,
        'commentsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection(userCollection).doc(uid).update({
        'postsCount': FieldValue.increment(1),
      });

      // Create notifications for followers
      List<dynamic> followers = userData['followers'] ?? [];
      if (followers.isNotEmpty) {
        for (var followerId in followers) {
          await _notificationService.createNotification(
            userId: followerId,
            type: 'post',
            message: '${userData['userName'] ?? 'Someone'} created a new post',
            postId: postRef.id,
            additionalData: {
              'title': 'New Post',
              'postId': postRef.id,
            },
          );
        }
      }

      return postRef.id;
    } catch (e) {
      return null;
    }
  }

  /// 🔹 Get Feed Posts
  Future<List<Map<String, dynamic>>> getFeedPosts() async {
    try {
      if (_auth.currentUser == null) throw _authException();

      String uid = _auth.currentUser!.uid;
      DocumentSnapshot userDoc =
          await _firestore.collection(userCollection).doc(uid).get();
      List<dynamic> following =
          (userDoc.data() as Map<String, dynamic>)['following'] ?? [];
      following.add(uid); // Include current user's posts

      QuerySnapshot postsSnapshot = await _firestore
          .collection(postsCollection)
          .where('userId', whereIn: following)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return await _processPosts(postsSnapshot, uid);
    } catch (e) {
      return [];
    }
  }

  /// 🔹 Get User Posts
  Future<List<Map<String, dynamic>>> getUserPosts(
      [String? userId]) async {
    try {
      if (_auth.currentUser == null) throw _authException();

      String targetUid = userId ?? _auth.currentUser!.uid;
      QuerySnapshot postsSnapshot = await _firestore
          .collection(postsCollection)
          .where('userId', isEqualTo: targetUid)
          .orderBy('createdAt', descending: true)
          .get();

      return await _processPosts(postsSnapshot, _auth.currentUser!.uid);
    } catch (e) {
      return [];
    }
  }

  /// 🔹 Toggle Like on a Post
  Future<bool> toggleLikePost(String postId) async {
    try {
      if (_auth.currentUser == null) throw _authException();

      String uid = _auth.currentUser!.uid;
      DocumentReference postRef =
          _firestore.collection(postsCollection).doc(postId);
      DocumentReference likeRef = postRef.collection(likesCollection).doc(uid);

      DocumentSnapshot likeDoc = await likeRef.get();
      bool isLiked = likeDoc.exists;

      if (isLiked) {
        await likeRef.delete();
        await postRef.update({'likesCount': FieldValue.increment(-1)});
        await _firestore
            .collection(userCollection)
            .doc(uid)
            .update({'likesCount': FieldValue.increment(-1)});
      } else {
        await likeRef
            .set({'userId': uid, 'createdAt': FieldValue.serverTimestamp()});
        await postRef.update({'likesCount': FieldValue.increment(1)});
        await _firestore
            .collection(userCollection)
            .doc(uid)
            .update({'likesCount': FieldValue.increment(1)});
            
        // Get post data to create notification
        DocumentSnapshot postDoc = await postRef.get();
        if (postDoc.exists) {
          Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
          String postUserId = postData['userId'];
          
          // Don't create notification if user is liking their own post
          if (postUserId != uid) {
            // Get current user data
            DocumentSnapshot userDoc = await _firestore.collection(userCollection).doc(uid).get();
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            
            // Create like notification
            await _notificationService.createNotification(
              userId: postUserId,
              type: 'like',
              message: '${userData['userName'] ?? 'Someone'} liked your post',
              postId: postId,
              likeId: uid,
              additionalData: {
                'title': 'New Like',
                'postId': postId,
              },
            );
          }
        }
      }

      return !isLiked;
    } catch (e) {
      return false;
    }
  }

  /// 🔹 Helper: Process Posts
  Future<List<Map<String, dynamic>>> _processPosts(
      QuerySnapshot postsSnapshot, String uid) async {
    List<Map<String, dynamic>> posts = [];

    for (var doc in postsSnapshot.docs) {
      Map<String, dynamic> postData = doc.data() as Map<String, dynamic>;
      DocumentSnapshot likeDoc = await _firestore
          .collection(postsCollection)
          .doc(doc.id)
          .collection(likesCollection)
          .doc(uid)
          .get();

      posts.add({
        ...postData,
        'id': doc.id,
        'isLiked': likeDoc.exists,
        'createdAt': postData['createdAt'] != null
            ? (postData['createdAt'] as Timestamp).toDate().toString()
            : DateTime.now().toString(),
      });
    }

    return posts;
  }

  /// 🔹 Helper: Throw Authentication Exception
  FirebaseException _authException() {
    return FirebaseException(
      plugin: 'firebase_firestore',
      code: 'unauthenticated',
      message: 'User must be logged in to perform this operation',
    );
  }
}
