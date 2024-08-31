import 'dart:io';
import 'package:aurora/main.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Login'),
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                child: Image.asset('assets/images/login-asset.png',
                    height: 200, width: 200),
              ),
              const SizedBox(height: 20),
              _buildTextField(userName, 'Username', IconlyBold.profile),
              const SizedBox(height: 10),
              _buildTextField(passWord, 'Password', IconlyBold.lock,
                  obscureText: true),
              const SizedBox(height: 20),
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _saveUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.onPrimaryFixedVariant,
                    foregroundColor: Theme.of(context).colorScheme.inverseSurface == Theme.of(context).colorScheme.onPrimaryFixedVariant ? Colors.black : 
Theme.of(context).colorScheme.onPrimaryFixedVariant == Color(0xffe2e2e2) ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Submit',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inverseSurface == Theme.of(context).colorScheme.onPrimaryFixedVariant ? Colors.black : 
Theme.of(context).colorScheme.onPrimaryFixedVariant == Color(0xffe2e2e2) ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Divider(
                color: Theme.of(context).colorScheme.outline,
                thickness: 1,
              ),
              const SizedBox(height: 20),
              Text(
                'Or sign in with',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildSocialButton(
                  'Google', Ionicons.logo_google, _loginWithGoogle),
              const SizedBox(height: 10),
              _buildSocialButton(
                  'Facebook', Ionicons.logo_facebook, _loginWithFacebook),
            ],
          ),
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
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildSocialButton(
      String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Theme.of(context).colorScheme.inverseSurface == Theme.of(context).colorScheme.onPrimaryFixedVariant ? Colors.black : 
Theme.of(context).colorScheme.onPrimaryFixedVariant == Color(0xffe2e2e2) ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainApp()),
      (route) => false,
    );
  }

  void _loginWithGoogle() {}

  void _loginWithFacebook() {}
}
