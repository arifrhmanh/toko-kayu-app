import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/customer/alamat_screen.dart';
import 'package:frontend/utils/helpers.dart';
import 'package:iconsax/iconsax.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          if (user == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              children: [
                // Profile header
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Text(
                          user.namaLengkap.isNotEmpty ? user.namaLengkap[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.namaLengkap, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('@${user.username}', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Menu items
                _buildMenuItem(context, icon: Iconsax.location, title: 'Alamat Saya', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AlamatScreen()));
                }),
                _buildMenuItem(context, icon: Iconsax.user_edit, title: 'Edit Profil', onTap: () {}),
                _buildMenuItem(context, icon: Iconsax.lock, title: 'Ubah Password', onTap: () {}),
                const Divider(height: 32),
                _buildMenuItem(context, icon: Iconsax.logout, title: 'Keluar', isDestructive: true, onTap: () async {
                  final confirm = await showConfirmDialog(context, title: 'Keluar', message: 'Yakin ingin keluar?', isDestructive: true);
                  if (confirm) authProvider.logout();
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.shadowSmall),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor),
        title: Text(title, style: TextStyle(color: isDestructive ? AppTheme.errorColor : null)),
        trailing: const Icon(Iconsax.arrow_right_3, size: 18),
        onTap: onTap,
      ),
    );
  }
}
