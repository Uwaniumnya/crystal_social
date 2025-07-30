import 'package:flutter/material.dart';
import 'notes_main.dart';

/// Integration examples for adding Notes to the main Crystal app
/// This file shows various ways to integrate the Notes app

// 1. Add to main tabs or home screen:
class NotesTabExample extends StatelessWidget {
  final String currentUserId;
  
  const NotesTabExample({super.key, required this.currentUserId});

  Widget _buildNotesTab() {
    return NotesLauncher(
      userId: currentUserId, // Pass the current user ID
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildNotesTab();
  }
}

// 2. For tab navigation integration:
class TabNavigationExample extends StatelessWidget {
  final String currentUserId;
  
  const TabNavigationExample({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Home'),
              Tab(text: 'Notes'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const Center(child: Text('Home Tab')),
            NotesMain(userId: currentUserId), // Direct integration
            const Center(child: Text('Settings Tab')),
          ],
        ),
      ),
    );
  }
}

// 3. For drawer/menu integration:
class DrawerIntegrationExample extends StatelessWidget {
  final String currentUserId;
  
  const DrawerIntegrationExample({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crystal App')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text('Crystal App'),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.note_alt_outlined),
              title: const Text('Notes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotesMain(userId: currentUserId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Main App Content'),
      ),
    );
  }
}

// 4. For home screen cards/tiles:
class HomeScreenIntegration extends StatelessWidget {
  final String currentUserId;

  const HomeScreenIntegration({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crystal Apps')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          // Game Corner (example)
          _buildAppCard(
            context,
            'Game Corner',
            Icons.games,
            Colors.blue,
            () {
              // Navigate to game corner
            },
          ),
          
          // Notes app
          NotesLauncher(userId: currentUserId),
          
          // Music (example)
          _buildAppCard(
            context,
            'Music',
            Icons.music_note,
            Colors.green,
            () {
              // Navigate to music
            },
          ),
          
          // Settings (example)
          _buildAppCard(
            context,
            'Settings',
            Icons.settings,
            Colors.orange,
            () {
              // Navigate to settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.6),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 5. Simple button integration:
class SimpleButtonIntegration extends StatelessWidget {
  final String currentUserId;
  
  const SimpleButtonIntegration({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crystal App')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotesMain(userId: currentUserId),
              ),
            );
          },
          icon: const Icon(Icons.note_add),
          label: const Text('Open Notes'),
        ),
      ),
    );
  }
}

// 6. Bottom navigation integration:
class BottomNavigationIntegration extends StatefulWidget {
  final String currentUserId;
  
  const BottomNavigationIntegration({super.key, required this.currentUserId});

  @override
  State<BottomNavigationIntegration> createState() => _BottomNavigationIntegrationState();
}

class _BottomNavigationIntegrationState extends State<BottomNavigationIntegration> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const Center(child: Text('Home Screen')),
          NotesMain(userId: widget.currentUserId),
          const Center(child: Text('Profile Screen')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
