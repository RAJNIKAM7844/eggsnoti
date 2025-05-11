import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  String _errorMessage = '';
  String? _profileImageUrl;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _errorMessage = 'User is not logged in';
          _isLoading = false;
        });
        return;
      }
      final response =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();
      if (response == null) {
        setState(() {
          _errorMessage = 'User profile not found';
          _isLoading = false;
        });
        return;
      }
      _profileImageUrl = await _getValidImageUrl(response['profile_image']);
      setState(() {
        userData = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<String?> _getValidImageUrl(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    try {
      if (imagePath.startsWith('userprofile/')) {
        final String publicUrl = _supabase.storage
            .from('userprofile')
            .getPublicUrl(imagePath.replaceFirst('userprofile/', ''));
        await Supabase.instance.client.storage
            .from('userprofile')
            .download(imagePath.replaceFirst('userprofile/', ''));
        return publicUrl;
      }
      return imagePath;
    } catch (e) {
      print('Error verifying image URL: $e');
      return null;
    }
  }

  Future<void> _refreshData() async {
    await _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: CustomBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFFFF6F00),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align content to the left
                children: [
                  SizedBox(height: size.height * 0.02),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: size.width * 0.04),
                    child: Text(
                      'Profile',
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  AnimatedOpacity(
                    opacity: _isLoading ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.04),
                            child: Text(
                              _errorMessage,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: const Color(0xFFD32F2F),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: size.width * 0.15,
                              backgroundColor: const Color(0xFFF5F5F5),
                              backgroundImage: _profileImageUrl != null
                                  ? NetworkImage(_profileImageUrl!)
                                  : null,
                              child: _profileImageUrl == null
                                  ? Icon(Icons.person,
                                      size: size.width * 0.15,
                                      color: const Color(0xFF757575))
                                  : null,
                            ),
                            if (_isLoading)
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xFFFF6F00)),
                              ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: size.width * 0.06,
                                height: size.width * 0.06,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF388E3C),
                                  shape: BoxShape.circle,
                                  border: Border.fromBorderSide(BorderSide(
                                      color: Colors.white, width: 2)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.02),
                        _buildInfoField(
                          icon: Icons.person,
                          text: userData?['full_name'] ?? "No name provided",
                        ),
                        _buildInfoField(
                          icon: Icons.mail,
                          text: userData?['email'] ?? "No email provided",
                        ),
                        _buildInfoField(
                          icon: Icons.location_on,
                          text: userData?['location'] ?? "No location provided",
                        ),
                        _buildInfoField(
                          icon: Icons.phone,
                          text: userData?['phone'] ?? "No phone provided",
                        ),
                        SizedBox(height: size.height * 0.03),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.04),
                          child: ElevatedButton(
                            onPressed: () async {
                              await _supabase.auth.signOut();
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: const Text("Log Out"),
                            style: ElevatedButton.styleFrom(
                              minimumSize:
                                  Size(size.width * 0.9, size.height * 0.06),
                              backgroundColor: const Color(0xFF0288D1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.04),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField({required IconData icon, required String text}) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04, vertical: size.height * 0.01),
      child: Card(
        elevation: 4, // Slightly reduced for a flatter look
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
          side: BorderSide(
            color:
                const Color(0xFF0288D1).withOpacity(0.2), // Subtle blue border
            width: 1,
          ),
        ),
        color: Colors.white, // Clean white background
        child: ListTile(
          leading: Icon(
            icon,
            color: const Color(0xFF0288D1),
            size: size.width * 0.05,
          ),
          title: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: const Color(0xFF757575), // Darker text for contrast
                  fontSize: size.width * 0.04,
                ),
            overflow: TextOverflow.ellipsis,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.height * 0.005,
          ),
        ),
      ),
    );
  }
}
