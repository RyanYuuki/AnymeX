import 'package:anymex/screens/settings/sub_settings/settings_about.dart';
import 'package:flutter/material.dart';

class ProfileInfo extends StatelessWidget {
  final String username;
  final String version;
  final String subtitle;

  const ProfileInfo({
    super.key,
    required this.username,
    required this.version,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          username,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          version,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontFamily: "Poppins-SemiBold",
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.5)),
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded)),
      ],
    );
  }
}

class ProfileSection extends StatelessWidget {
  final String username;
  final String version;
  final String subtitle;

  const ProfileSection({
    super.key,
    required this.username,
    required this.version,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage('assets/images/logo.png'),
                fit: BoxFit.cover,
              ),
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            username,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            version,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          InfoCard(
            onTap: () async {
              await launchUrlHelper('https://github.com/');
            },
            leading: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/logo.png'),
            ),
            title: "Developer",
            subtitle: "RyanYuuki",
            trailing: IconButton(
                onPressed: () async {
                  await launchUrlHelper('https://github.com/');
                },
                icon: const Icon(Icons.code)),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Function()? onTap;

  const InfoCard({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class CustomSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> items;
  final IconData icon;
  const CustomSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12))),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16, fontFamily: 'Poppins-SemiBold'),
                    ),
                    if (subtitle != null)
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 100,
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          ...items,
        ],
      ),
    );
  }
}

class CustomListTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final Widget? trailing;
  final Function()? onTap;
  final String? subtitle;

  const CustomListTile({
    super.key,
    required this.leading,
    required this.title,
    this.trailing,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            IconTheme(
              data:
                  IconThemeData(color: theme.colorScheme.onSecondaryContainer),
              child: leading,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.9),
                        fontFamily: 'Poppins-SemiBold'),
                  ),
                  const SizedBox(height: 1),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    )
                ],
              ),
            ),
            if (trailing != null)
              IconTheme(
                data: IconThemeData(color: theme.colorScheme.onSurface),
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}
