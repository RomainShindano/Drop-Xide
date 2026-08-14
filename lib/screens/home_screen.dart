import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/build_provider.dart';
import '../widgets/project_list_widget.dart';
import '../widgets/build_config_widget.dart';
import '../widgets/build_history_widget.dart';
import 'add_project_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drop-Xide'),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToAddProject(),
              tooltip: 'Add Project',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: Text('Projects'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.build_outlined),
                selectedIcon: Icon(Icons.build),
                label: Text('Build'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history),
                selectedIcon: Icon(Icons.history),
                label: Text('History'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const ProjectListWidget();
      case 1:
        return const BuildConfigWidget();
      case 2:
        return const BuildHistoryWidget();
      case 3:
        return _buildSettingsContent();
      default:
        return const Center(child: Text('Unknown page'));
    }
  }

  Widget _buildSettingsContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('Coming soon...'),
        ],
      ),
    );
  }

  Future<void> _navigateToAddProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProjectScreen()),
    );

    if (result == true && mounted) {
      context.read<ProjectProvider>().loadProjects();
    }
  }

  void _refreshData() {
    context.read<ProjectProvider>().loadProjects();
    context.read<BuildProvider>().loadBuildHistory();
  }
}
