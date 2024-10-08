import 'package:aurora/auth/auth_provider.dart'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SampleAnilist extends StatelessWidget {
  const SampleAnilist({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AniList Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Provider.of<AniListProvider>(context, listen: false).login(context);
          },
          child: const Text('Login with AniList'),
        ),
      ),
    );
  }
}

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  @override
  void initState() {
    super.initState();
    Provider.of<AniListProvider>(context, listen: false).fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AniListProvider>(context);
    final userData = provider.userData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AniList User Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              provider.logout(context);
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(userData['avatar']['large']),
                    radius: 50,
                  ),
                  const SizedBox(height: 16),
                  Text('Name: ${userData['name']}'),
                  const SizedBox(height: 8),
                  Text('Anime Watched: ${userData['statistics']['anime']['count']}'),
                  Text('Manga Read: ${userData['statistics']['manga']['count']}'),
                ],
              ),
            ),
    );
  }
}
