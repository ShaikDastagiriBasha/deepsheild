import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isSendingReset = false;

  Future<void> _sendPasswordReset() async {
    if (user?.email == null) return;
    setState(() {
      isSendingReset = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text("Password reset link sent to ${user!.email}"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
              "Unable to send the password reset email. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSendingReset = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String email = user?.email ?? "N/A";
    final bool isEmailVerified = user?.emailVerified ?? false;
    final String lastLogin = user?.metadata.lastSignInTime != null
        ? "${user!.metadata.lastSignInTime!.day}/${user!.metadata.lastSignInTime!.month}/${user!.metadata.lastSignInTime!.year} ${user!.metadata.lastSignInTime!.hour}:${user!.metadata.lastSignInTime!.minute.toString().padLeft(2, '0')}"
        : "Active Session";

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Privacy & Security"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Security Settings",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Manage account access, password and session encryption.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 25),

              // ACCOUNT SECURITY CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildSecurityRow(
                      icon: Icons.email_outlined,
                      title: "Registered Email",
                      subtitle: email,
                      badge: isEmailVerified ? "Verified" : "Unverified",
                      badgeColor: isEmailVerified
                          ? Colors.greenAccent
                          : Colors.amberAccent,
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    _buildSecurityRow(
                      icon: Icons.history,
                      title: "Last Sign-In Timestamp",
                      subtitle: lastLogin,
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    _buildSecurityRow(
                      icon: Icons.lock_clock_outlined,
                      title: "Encryption Standard",
                      subtitle: "AES-256 Cloud Firestore Security Rules",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Actions",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // RESET PASSWORD BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: isSendingReset ? null : _sendPasswordReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: isSendingReset
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_reset, color: Colors.white),
                  label: const Text(
                    "Send Password Reset Email",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityRow({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryAccent, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (badgeColor ?? Colors.white).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeColor ?? Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
