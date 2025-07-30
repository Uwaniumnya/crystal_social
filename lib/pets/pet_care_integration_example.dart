// Example integration file: pet_care_integration_example.dart
// This shows how to integrate the pet care screen into your app

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pet_care_screen.dart';
import 'pet_state_provider.dart';

class PetIntegrationExample extends StatelessWidget {
  final String userId;

  const PetIntegrationExample({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pet'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PetState>(
        builder: (context, petState, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.purple.shade100, Colors.pink.shade100],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pet summary card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
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
                            'Level ${petState.bondLevel} • ${petState.petAge}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Quick stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickStat(
                                'Happiness',
                                '${(petState.happiness * 100).round()}%',
                                Icons.sentiment_very_satisfied,
                                Colors.yellow,
                              ),
                              _buildQuickStat(
                                'Energy',
                                '${(petState.energy * 100).round()}%',
                                Icons.battery_charging_full,
                                Colors.green,
                              ),
                              _buildQuickStat(
                                'Health',
                                '${(petState.health * 100).round()}%',
                                Icons.favorite,
                                Colors.red,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Care button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PetCareScreen(
                                      userId: userId,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.pets, size: 24),
                              label: const Text(
                                'Care for Your Pet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Quick action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Quick feed action
                                    _quickFeed(context, petState);
                                  },
                                  icon: const Icon(Icons.restaurant),
                                  label: const Text('Quick Feed'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: const BorderSide(color: Colors.orange),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Quick play action
                                    _quickPlay(context, petState);
                                  },
                                  icon: const Icon(Icons.sports_esports),
                                  label: const Text('Quick Play'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    side: const BorderSide(color: Colors.green),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Achievement showcase
                  if (petState.achievements.isNotEmpty)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  'Recent Achievements',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${petState.achievements.length} achievements unlocked!',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _quickFeed(BuildContext context, PetState petState) {
    // Simple quick feed with basic food
    petState.updateStats(
      happinessChange: 0.1,
      energyChange: 0.1,
      healthChange: 0.05,
    );
    petState.increaseBondXP(5);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.restaurant, color: Colors.white),
            const SizedBox(width: 8),
            Text('Fed ${petState.petName} a quick snack!'),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _quickPlay(BuildContext context, PetState petState) {
    // Simple quick play session
    if (petState.energy > 0.1) {
      petState.updateStats(
        happinessChange: 0.15,
        energyChange: -0.05,
        healthChange: 0.02,
      );
      petState.increaseBondXP(8);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sports_esports, color: Colors.white),
              const SizedBox(width: 8),
              Text('Had a quick play session with ${petState.petName}!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.battery_0_bar, color: Colors.white),
              const SizedBox(width: 8),
              Text('${petState.petName} is too tired to play!'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

// Usage in main app:
/*
// In your main widget tree, wrap with PetState provider:
ChangeNotifierProvider(
  create: (context) => PetState(),
  child: MaterialApp(
    home: PetIntegrationExample(userId: 'your-user-id'),
  ),
)

// Or navigate to it from another screen:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PetIntegrationExample(userId: currentUserId),
  ),
);
*/
