// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'processing_screen.dart'; // Navigate to next screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    final bytes = await image.readAsBytes();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(originalBytes: bytes),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Color Balance")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 80, color: Colors.white24),
            const SizedBox(height: 20),
            const Text("Discover your palette", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_a_photo),
              label: const Text("Analyze Photo"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}