import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';

class RealtimeDatabaseExample extends StatefulWidget {
  const RealtimeDatabaseExample({super.key});

  @override
  State<RealtimeDatabaseExample> createState() =>
      _RealtimeDatabaseExampleState();
}

class _RealtimeDatabaseExampleState extends State<RealtimeDatabaseExample> {
  final DatabaseService _databaseService = DatabaseService();
  Stream<DatabaseEvent>? _dataStream;
  String _displayData = '';

  @override
  void initState() {
    super.initState();
    // Start listening to real-time updates
    _dataStream = _databaseService.streamData('example/data');
  }

  Future<void> _writeData() async {
    try {
      await _databaseService.writeData('example/data', {
        'message': 'Hello from Velora!',
        'timestamp': DateTime.now().toIso8601String(),
      });
      print('Data written successfully');
    } catch (e) {
      print('Error writing data: $e');
    }
  }

  Future<void> _readData() async {
    try {
      final data = await _databaseService.readData('example/data');
      setState(() {
        _displayData = data.toString();
      });
    } catch (e) {
      print('Error reading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime Database Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Stream builder to show real-time updates
            StreamBuilder<DatabaseEvent>(
              stream: _dataStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final dynamic data = snapshot.data?.snapshot.value;
                return Text('Real-time data: ${data.toString()}');
              },
            ),
            const SizedBox(height: 20),
            Text('Last read data: $_displayData'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _writeData,
              child: const Text('Write Data'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _readData,
              child: const Text('Read Data'),
            ),
          ],
        ),
      ),
    );
  }
}
