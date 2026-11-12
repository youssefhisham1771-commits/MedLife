import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() =>
      _SendNotificationScreenState();
}

class _SendNotificationScreenState
    extends State<SendNotificationScreen> {

  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  Future<void> sendNotification() async {

    if (titleController.text.trim().isEmpty ||
        bodyController.text.trim().isEmpty) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
      'title': titleController.text.trim(),
      'body': bodyController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Notification Sent"),
      ),
    );

    titleController.clear();
    bodyController.clear();
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Notification"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Title",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: bodyController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Message",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: sendNotification,
              child: const Text("Send"),
            ),
          ],
        ),
      ),
    );
  }
}