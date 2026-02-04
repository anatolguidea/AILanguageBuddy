import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../auth/presentation/auth_state.dart';
import '../../../auth/data/auth_repository.dart';
import '../widgets/profile_list_tile.dart';
import '../widgets/profile_section.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text("Not Logged In"));
          }
          final email = user.email ?? 'No Email';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  child: Icon(FontAwesomeIcons.userAstronaut, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  email,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                
                ProfileSection(title: "Settings", children: [
                  ProfileListTile(
                    icon: FontAwesomeIcons.language,
                    title: "Language Preferences",
                    onTap: () {},
                  ),
                  ProfileListTile(
                    icon: FontAwesomeIcons.bell,
                    title: "Notifications",
                    onTap: () {},
                  ),
                  ProfileListTile(
                    icon: FontAwesomeIcons.moon,
                    title: "Dark Mode",
                    onTap: () {},
                  ),
                ]),

                const SizedBox(height: 24),
                
                ProfileSection(title: "Account", children: [
                  ProfileListTile(
                    icon: FontAwesomeIcons.arrowRightFromBracket,
                    title: "Sign Out",
                    iconColor: AppColors.error,
                    textColor: AppColors.error,
                    onTap: () async {
                       await ref.read(authRepositoryProvider).signOut();
                    },
                  ),
                ]),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
