import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_lock_provider.dart';
import '../services/installed_apps_service.dart';
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search apps...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Consumer<AppLockProvider>(
                  builder: (context, provider, child) {
                    return ListView.builder(
                      itemCount: _filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = _filteredApps[index];
                        final isLocked = provider.isAppLocked(app.packageName);
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: app.icon != null
                                ? Image.memory(
                                    app.icon!,
                                    width: 48,
                                    height: 48,
                                  )
                                : const CircleAvatar(
                                    child: Icon(Icons.android),
                                  ),
                            title: Text(app.appName),
                            subtitle: Text(app.packageName),
                            trailing: isLocked
                                ? const Icon(Icons.lock, color: Colors.green)
                                : const Icon(Icons.lock_open),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AppLockSetupScreen(
                                    app: app,
                                    isLocked: isLocked,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
