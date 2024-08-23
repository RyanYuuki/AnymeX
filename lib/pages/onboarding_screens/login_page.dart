import 'dart:io';
import 'package:aurora/main.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userName = TextEditingController();
  final TextEditingController passWord = TextEditingController();
  File? _avatarImage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text(
              'Hello!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 50),
            const Text(
              "Welcome, you've been missed",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _avatarImage != null ? FileImage(_avatarImage!) : null,
                child: _avatarImage == null
                    ? const Icon(Icons.add_a_photo, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 50),
            _buildTextField(userName, 'Username', Icons.person),
            const SizedBox(height: 10),
            _buildTextField(passWord, 'Password', Icons.lock,
                obscureText: true),
            const SizedBox(height: 30),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 45,
              child: ElevatedButton(
                onPressed: _saveUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hintText, IconData icon,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        color: Theme.of(context).colorScheme.inverseSurface,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context).colorScheme.secondary,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImage =
          await File(pickedFile.path).copy('${directory.path}/$fileName');

      setState(() {
        _avatarImage = savedImage;
      });
    }
  }

  Future<void> _saveUserData() async {
    var box = Hive.box('login-data');
    box.put('userInfo', [
      userName.text,
      passWord.text,
      _avatarImage?.path,
    ]);
    box.put('isFirstTime', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainApp()),
    );
  }
}
