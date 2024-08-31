import 'dart:io';
import 'package:aurora/main.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AvatarPage extends StatefulWidget {
  const AvatarPage({super.key});

  @override
  State<AvatarPage> createState() => _AvatarPageState();
}

class _AvatarPageState extends State<AvatarPage> {
  final TextEditingController userName = TextEditingController();
  final TextEditingController passWord = TextEditingController();
  File? _avatarImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height / 6),
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) {
                    return AvatarModal(
                      onAvatarSelected: (File avatar) {
                        setState(() {
                          _avatarImage = avatar;
                        });
                      },
                    );
                  },
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _avatarImage != null ? FileImage(_avatarImage!) : null,
                  child: _avatarImage == null
                      ? const Icon(IconlyBold.image, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select your avatar image',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              _buildTextField(userName, 'Name', Iconsax.language_circle),
              const SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 60,
                child: ElevatedButton(
                  onPressed: _saveUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.onPrimaryFixedVariant,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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
        suffixIcon: Icon(icon),
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(20),
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
      (Route<dynamic> route) => false,
    );
  }
}

class AvatarModal extends StatefulWidget {
  final Function(File) onAvatarSelected;

  const AvatarModal({required this.onAvatarSelected, super.key});

  @override
  State<AvatarModal> createState() => _AvatarModalState();
}

class _AvatarModalState extends State<AvatarModal> {
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImage =
          await File(pickedFile.path).copy('${directory.path}/$fileName');

      widget.onAvatarSelected(savedImage);
      Navigator.pop(context);
    }
  }

  Future<void> _selectAvatar(String assetPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = path.basename(assetPath);
    final byteData = await DefaultAssetBundle.of(context).load(assetPath);
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    widget.onAvatarSelected(file);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Choose your avatar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(IconlyBold.image, size: 50),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        _selectAvatar('assets/images/avatars/avatar1.png'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/avatars/avatar1.png',
                        fit: BoxFit.cover,
                        height: 50,
                        width: 50,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        _selectAvatar('assets/images/avatars/avatar2.png'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/avatars/avatar2.png',
                        height: 50,
                        width: 50,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        _selectAvatar('assets/images/avatars/avatar3.png'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/avatars/avatar3.png',
                        height: 50,
                        width: 50,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        _selectAvatar('assets/images/avatars/avatar4.png'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/avatars/avatar4.png',
                        height: 50,
                        width: 50,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        _selectAvatar('assets/images/avatars/avatar5.png'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/avatars/avatar5.png',
                        height: 50,
                        width: 50,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
