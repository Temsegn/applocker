import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_lock_provider.dart';
import '../services/installed_apps_service.dart';
import '../utils/responsive.dart';
import 'app_lock_setup_screen.dart';

class AppListScreen extends StatefulWidget {
  const AppListScreen({super.key});

  @override
  State<AppListScreen> createState() => _AppListScreenState();
}

class _AppListScreenState extends State<AppListScreen> {
  List<InstalledApp> _installedApps = [];
  List<InstalledApp> _filteredApps = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
    _searchController.addListener(_filterApps);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstalledApps() async {
    try {
      final apps = await InstalledAppsService.getInstalledApps(
        includeSystemApps: false,
        includeAppIcons: true,
      );
      setState(() {
        _installedApps = apps;
        _filteredApps = apps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterApps() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredApps = _installedApps;
      } else {
        _filteredApps = _installedApps
            .where((app) => app.appName.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = Responsive.horizontalPadding(context);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search apps...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _isLoading
                ? Center(
                    key: const ValueKey('loading'),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )
                : Consumer<AppLockProvider>(
                    key: const ValueKey('list'),
                  builder: (context, provider, child) {
                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
                      cacheExtent: 240,
                      itemCount: _filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = _filteredApps[index];
                        final isLocked = provider.isAppLocked(app.packageName);
                        return TweenAnimationBuilder<double>(
                          key: ValueKey(app.packageName),
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 180 + (index > 12 ? 0 : index * 25)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 8 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: Card(
                            child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: app.icon != null
                                  ? Image.memory(
                                      app.icon!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    )
                                  : CircleAvatar(
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Icon(
                                        Icons.android_rounded,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                            ),
                            title: Text(
                              app.appName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              app.packageName,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(
                              isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                              color: isLocked
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                              size: 22,
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => AppLockSetupScreen(
                                    app: app,
                                    isLocked: isLocked,
                                  ),
                                  transitionsBuilder: (_, animation, __, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero)
                                            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 250),
                                ),
                              );
                            },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                ),
        ),
      ],
    );
  }
}
