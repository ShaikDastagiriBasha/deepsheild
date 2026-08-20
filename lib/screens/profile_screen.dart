import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/profile_image_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'profile/about_screen.dart';
import 'profile/ai_preferences_screen.dart';
import 'profile/privacy_security_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService authService = AuthService();
  final User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  final ProfileImageService _profileImageService = ProfileImageService();
  File? _localProfileImage;
  bool _isPickingImage = false;
  ImageSource? _pickingSource;

  void _showEditProfileModal(BuildContext context, String currentUsername) {
    final TextEditingController nameController =
        TextEditingController(text: currentUsername);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final messenger = ScaffoldMessenger.of(context);
            Future<void> pickImage(ImageSource source) async {
              if (_isPickingImage) return;
              setModalState(() {
                _isPickingImage = true;
                _pickingSource = source;
              });
              try {
                final XFile? picked =
                    await _picker.pickImage(source: source, imageQuality: 70);
                if (picked != null && mounted) {
                  setState(() {
                    _localProfileImage = File(picked.path);
                  });
                  setModalState(() {});
                }
              } catch (e, stackTrace) {
                debugPrint('IMAGE:PICK FAILED: ${e.runtimeType}');
                debugPrint('IMAGE:PICK ERROR: $e');
                debugPrintStack(stackTrace: stackTrace);
                if (mounted) {
                  messenger.showSnackBar(SnackBar(
                    content: Text(source == ImageSource.camera
                        ? 'Unable to capture the image. Please try again.'
                        : 'Unable to select the image. Please try again.'),
                  ));
                }
              } finally {
                if (mounted) {
                  setModalState(() {
                    _isPickingImage = false;
                    _pickingSource = null;
                  });
                }
              }
            }

            Future<void> saveProfile() async {
              if (user == null) return;
              final String newName = nameController.text.trim();
              if (newName.isEmpty) return;

              setModalState(() {
                isSaving = true;
              });

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                // Update Firebase User Display Name
                await user!.updateDisplayName(newName);

                // Upload image if changed
                String? newPhotoUrl;
                if (_localProfileImage != null) {
                  newPhotoUrl = await _profileImageService
                      .uploadProfileImage(_localProfileImage!);
                }

                // Update Cloud Firestore User Record
                final updateData = {
                  "username": newName,
                  "email": user!.email ?? "",
                  "updatedAt": FieldValue.serverTimestamp(),
                  "phoneNumber": user!.phoneNumber ?? "",
                  "lastLogin": user!.metadata.lastSignInTime != null
                      ? user!.metadata.lastSignInTime!.toIso8601String()
                      : DateTime.now().toIso8601String(),
                  "accountStatus": "AI Verified",
                };

                if (newPhotoUrl != null) {
                  updateData["profileImageUrl"] = newPhotoUrl;
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .set(updateData, SetOptions(merge: true));

                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Profile updated successfully."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Profile save error: $e");
                setModalState(() {
                  isSaving = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Edit Profile",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: AppTheme.primaryColor,
                          backgroundImage: _localProfileImage != null
                              ? FileImage(_localProfileImage!)
                              : null,
                          child: _localProfileImage == null
                              ? const Icon(Icons.security,
                                  size: 50, color: Colors.white)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.black, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _isPickingImage
                            ? null
                            : () => pickImage(ImageSource.camera),
                        icon: _isPickingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.camera_alt,
                                size: 16, color: AppTheme.primaryAccent),
                        label: Text(_isPickingImage
                            ? (_pickingSource == ImageSource.camera
                                ? 'Opening camera...'
                                : 'Opening gallery...')
                            : 'Camera',
                            style:
                                const TextStyle(color: AppTheme.primaryAccent)),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: _isPickingImage
                            ? null
                            : () => pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library,
                            size: 16, color: AppTheme.primaryAccent),
                        label: Text(_isPickingImage
                            ? (_pickingSource == ImageSource.camera
                                ? 'Opening camera...'
                                : 'Opening gallery...')
                            : 'Gallery',
                            style:
                                const TextStyle(color: AppTheme.primaryAccent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save Changes",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userEmail = user?.email ?? "analyst@deepshield.ai";
    final String fallbackName = user?.displayName ??
        (userEmail.contains('@') ? userEmail.split('@').first : "Analyst");

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE & EDIT BUTTON
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Profile & Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.edit, color: AppTheme.primaryAccent),
                      onPressed: () =>
                          _showEditProfileModal(context, fallbackName),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // PROFILE CARD WITH FIRESTORE STREAM SYNC
                StreamBuilder<DocumentSnapshot>(
                  stream: user != null
                      ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(user!.uid)
                          .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    String displayName = fallbackName;
                    String? photoPath;

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null) {
                        if ((data['username'] ?? "").toString().isNotEmpty) {
                          displayName = data['username'];
                        }
                        if ((data['profileImageUrl'] ?? "")
                            .toString()
                            .isNotEmpty) {
                          photoPath = data['profileImageUrl'];
                        } else if ((data['photoUrl'] ?? "")
                            .toString()
                            .isNotEmpty) {
                          photoPath = data['photoUrl'];
                        }
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppTheme.primaryColor,
                            backgroundImage: photoPath != null
                                ? (photoPath.startsWith('http')
                                    ? NetworkImage(photoPath) as ImageProvider
                                    : (File(photoPath).existsSync()
                                        ? FileImage(File(photoPath))
                                        : null))
                                : (_localProfileImage != null
                                    ? FileImage(_localProfileImage!)
                                    : null),
                            child: (photoPath == null &&
                                    _localProfileImage == null)
                                ? const Icon(
                                    Icons.security,
                                    size: 40,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "AI Verified Account",
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 35),

                const Text(
                  "Preferences",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                profileTile(
                  icon: Icons.lock_outline,
                  title: "Privacy & Security",
                  subtitle: "Data encryption & password reset",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PrivacySecurityScreen()),
                    );
                  },
                ),

                profileTile(
                  icon: Icons.shield_outlined,
                  title: "AI Engine Preferences",
                  subtitle: "MobileFaceNet & ML Kit model specs",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AiPreferencesScreen()),
                    );
                  },
                ),

                profileTile(
                  icon: Icons.info_outline,
                  title: "About DeepShield",
                  subtitle: "v1.0.0 • Engineering Project Info",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AboutScreen()),
                    );
                  },
                ),

                const SizedBox(height: 10),

                GestureDetector(
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final logoutMessage = await authService.logout();
                    if (!mounted) return;
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                    if (logoutMessage != null) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(logoutMessage)),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent, size: 26),
                        SizedBox(width: 16),
                        Text(
                          "Log Out",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget profileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryAccent,
              size: 26,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
