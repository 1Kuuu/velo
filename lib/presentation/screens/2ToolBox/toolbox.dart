import 'package:flutter/material.dart';

class Toolbox extends StatefulWidget {
  const Toolbox({super.key});

  @override
  _ToolboxState createState() => _ToolboxState();
}

class _ToolboxState extends State<Toolbox> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toolbox'),
      ),
      body: const Center(
        child: Text('Toolbox Page'),
      ),
    );
  }
}
