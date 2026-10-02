import 'package:flutter/material.dart';
import 'package:saber/data/app_launcher.dart';

Future<void> showAppLauncherDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const AppLauncherDialog(),
  );
}

class AppLauncherDialog extends StatefulWidget {
  const AppLauncherDialog({super.key});

  @override
  State<AppLauncherDialog> createState() => _AppLauncherDialogState();
}

class _AppLauncherDialogState extends State<AppLauncherDialog> {
  List<AppInfo>? apps;
  List<AppInfo> filtered = const [];
  String query = '';

  @override
  void initState() {
    super.initState();
    AppLauncher.listApps().then((loaded) {
      if (!mounted) return;
      setState(() {
        apps = loaded;
        filtered = _filter(query);
      });
    });
  }

  List<AppInfo> _filter(String query) {
    final apps = this.apps;
    if (apps == null) return const [];
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return apps;

    final prefix = <AppInfo>[];
    final substring = <AppInfo>[];
    for (final app in apps) {
      final label = app.label.toLowerCase();
      if (label.startsWith(q)) {
        prefix.add(app);
      } else if (label.contains(q)) {
        substring.add(app);
      }
    }
    return [...prefix, ...substring];
  }

  void _onQueryChanged(String query) {
    this.query = query;
    final filtered = _filter(query);

    // OLauncher behavior: launch immediately when exactly one app matches.
    if (query.trim().isNotEmpty && filtered.length == 1) {
      _launch(filtered.single);
      return;
    }

    setState(() => this.filtered = filtered);
  }

  void _launch(AppInfo app) {
    AppLauncher.launchApp(app.packageName);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                autofocus: true,
                onChanged: _onQueryChanged,
                onSubmitted: (_) {
                  if (filtered.isNotEmpty) _launch(filtered.first);
                },
                decoration: InputDecoration(
                  hintText: 'Search apps',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.onSurface,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            if (apps == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final app = filtered[index];
                    return ListTile(
                      title: Text(app.label),
                      onTap: () => _launch(app),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
