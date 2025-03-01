import 'package:flutter/material.dart';

class NewsFeed extends StatefulWidget {
  const NewsFeed({super.key});

  @override
  _NewsFeedState createState() => _NewsFeedState();
}

class _NewsFeedState extends State<NewsFeed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Feed'),
      ),
      body: const Center(
        child: Text('News Feed Page'),
      ),
    );
  }
}
