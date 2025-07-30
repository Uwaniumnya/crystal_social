// File: pets_integration_example.dart
// Example showing how to use the integrated pets system

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pets_integration.dart';

/// Example app showing integrated pets functionality
class PetsIntegratedApp extends StatelessWidget {
  const PetsIntegratedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pets Integration Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Builder(
        builder: (context) => PetsIntegration.wrapWithPetSystem(
          context: context,
          userId: 'example_user_id', // In real app, get from auth
          child: const PetsHomeScreen(),
        ),
      ),
    );
  }
}

class PetsHomeScreen extends StatelessWidget {
  const PetsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integrated Pets System'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade300,
              Colors.blue.shade300,
              Colors.pink.shade300,
            ],
          ),
        ),
        child: Consumer<PetState>(
          builder: (context, petState, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Pet Status Card
                  _buildPetStatusCard(petState),
                  
                  const SizedBox(height: 20),
                  
                  // Interactive Pet Display
                  _buildInteractivePet(context, petState),
                  
                  const SizedBox(height: 20),
                  
                  // Quick Actions
                  _buildQuickActions(context, petState),
                  
                  const SizedBox(height: 20),
                  
                  // Navigation Buttons
                  _buildNavigationButtons(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPetStatusCard(PetState petState) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              petState.petName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Level ${petState.bondLevel} • ${petState.currentMood.toUpperCase()}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatIndicator('❤️', petState.happiness, Colors.red),
                _buildStatIndicator('⚡', petState.energy, Colors.orange),
                _buildStatIndicator('💚', petState.health, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatIndicator(String emoji, double value, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          '${(value * 100).round()}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractivePet(BuildContext context, PetState petState) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Tap your pet to interact!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
            // Use integrated AnimatedPet
            PetsIntegration.createAnimatedPet(
              petId: petState.selectedPetId,
              accessory: petState.selectedAccessory,
              size: 200,
              enableSounds: !petState.isMuted,
              health: petState.health * 100,
              happiness: petState.happiness * 100,
              energy: petState.energy * 100,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${petState.petName} says hello! 🐾'),
                    backgroundColor: Colors.purple,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, PetState petState) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Note: These actions now give coins and points through the reward system!
                _buildActionButton(
                  context,
                  icon: Icons.restaurant,
                  label: 'Feed',
                  color: Colors.orange,
                  onPressed: () {
                    petState.feedPet(); // Use the proper method that includes rewards
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fed your pet! 🍖 (+5 coins)'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.sports_esports,
                  label: 'Play',
                  color: Colors.green,
                  onPressed: () {
                    petState.playWithPet(); // Use the proper method that includes rewards
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Played with your pet! 🎾 (+8 coins)'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.favorite,
                  label: 'Pet',
                  color: Colors.pink,
                  onPressed: () {
                    petState.increaseBondXP(10); // Give XP for petting
                    // Play pet sound using integrated system
                    PetsIntegration.playPetSound(petState.selectedPetId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Your pet feels loved! 💕'),
                        backgroundColor: Colors.pink,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Pet Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      PetsIntegration.navigateToPetDetails(context);
                    },
                    icon: const Icon(Icons.pets),
                    label: const Text('Pet Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      PetsIntegration.navigateToPetCare(context);
                    },
                    icon: const Icon(Icons.health_and_safety),
                    label: const Text('Pet Care'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Example usage in main.dart:
/// 
/// ```dart
/// void main() {
///   runApp(const PetsIntegratedApp());
/// }
/// ```
/// 
/// Note: This example shows the integrated pets system with:
/// - Enhanced reward system (coins and points for pet interactions)
/// - Three default pets unlocked (cat, dog, bunny)
/// - Pet level ups that give escalating currency rewards
/// - Achievement system with currency rewards
/// - Integration with main app progression system
/// 
/// Make sure to:
/// 1. Replace 'example_user_id' with actual user ID from authentication
/// 2. Set up proper RewardsManager integration in your main app
/// 3. Configure Supabase for pet data persistence
