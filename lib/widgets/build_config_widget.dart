import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/build_provider.dart';
import '../models/flutter_project.dart';

class BuildConfigWidget extends StatefulWidget {
  const BuildConfigWidget({super.key});

  @override
  State<BuildConfigWidget> createState() => _BuildConfigWidgetState();
}

class _BuildConfigWidgetState extends State<BuildConfigWidget> {
  BuildPlatform _selectedPlatform = BuildPlatform.android;
  BuildMode _selectedMode = BuildMode.release;
  String? _flavor;
  bool _obfuscate = false;
  bool _splitDebugInfo = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        final selectedProject = projectProvider.selectedProject;

        if (selectedProject == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.build_circle_outlined, size: 100, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'No Project Selected',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text('Select a project from the Projects tab to start building'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.folder, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedProject.name,
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    Text(
                                      selectedProject.path,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Build Configuration',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Platform',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: BuildPlatform.values.map((platform) {
                              return ChoiceChip(
                                label: Text(platform.name.toUpperCase()),
                                selected: _selectedPlatform == platform,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedPlatform = platform;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Build Mode',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: BuildMode.values.map((mode) {
                              return ChoiceChip(
                                label: Text(mode.name.toUpperCase()),
                                selected: _selectedMode == mode,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedMode = mode;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Advanced Options',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Flavor (Optional)',
                              hintText: 'e.g., dev, staging, production',
                            ),
                            onChanged: (value) {
                              _flavor = value.isEmpty ? null : value;
                            },
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: const Text('Obfuscate'),
                            subtitle: const Text('Obfuscate Dart code'),
                            value: _obfuscate,
                            onChanged: (value) {
                              setState(() {
                                _obfuscate = value;
                              });
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Split Debug Info'),
                            subtitle: const Text('Store debug information separately'),
                            value: _splitDebugInfo,
                            onChanged: (value) {
                              setState(() {
                                _splitDebugInfo = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Consumer<BuildProvider>(
                    builder: (context, buildProvider, child) {
                      final isBuilding = buildProvider.currentBuild?.status == BuildStatus.running;
                      
                      return FilledButton.icon(
                        onPressed: isBuilding ? null : () => _startBuild(context),
                        icon: isBuilding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.build),
                        label: Text(isBuilding ? 'Building...' : 'Start Build'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(20),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Consumer<BuildProvider>(
                    builder: (context, buildProvider, child) {
                      if (buildProvider.logs.isEmpty) return const SizedBox.shrink();

                      return Card(
                        child: Container(
                          height: 300,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Build Logs',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: buildProvider.clearLogs,
                                    tooltip: 'Clear logs',
                                  ),
                                ],
                              ),
                              const Divider(),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: buildProvider.logs.length,
                                  itemBuilder: (context, index) {
                                    return Text(
                                      buildProvider.logs[index],
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _startBuild(BuildContext context) {
    final project = context.read<ProjectProvider>().selectedProject!;
    final config = BuildConfig(
      mode: _selectedMode,
      platform: _selectedPlatform,
      flavor: _flavor,
      obfuscate: _obfuscate,
      splitDebugInfo: _splitDebugInfo,
    );

    context.read<BuildProvider>().startBuild(project, config);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Build started!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
