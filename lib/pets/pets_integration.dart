// File: pets_integration.dart
// Central integration hub for all pet-related functionality

export 'updated_pet_list.dart';
export 'pet_state_provider.dart';
export 'global_accessory_system.dart';
export 'animated_pet.dart';
export 'pet_widget.dart';
export 'pet_details_screen.dart';
export 'pet_care_screen.dart';
export 'pet_mini_games.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Re-export commonly used classes
import 'updated_pet_list.dart';
import 'pet_state_provider.dart';
import 'global_accessory_system.dart';
import 'animated_pet.dart';
import 'pet_widget.dart';
import 'pet_details_screen.dart';
import 'pet_care_screen.dart';
import '../rewards/rewards_manager.dart';
import 'pets_production_config.dart';
import 'pets_performance_optimizer.dart';

/// Central pets integration manager
/// Provides unified access to all pet functionality
class PetsIntegration {
  // Singleton pattern for global access
  static final PetsIntegration _instance = PetsIntegration._internal();
  factory PetsIntegration() => _instance;
  PetsIntegration._internal();

  // Global audio player for consistent sound management
  static final AudioPlayer _globalAudioPlayer = AudioPlayer();
  static AudioPlayer get audioPlayer => _globalAudioPlayer;

  // Pet sound cooldown management
  static final Map<String, DateTime> _petSoundCooldowns = {};
  static const Duration soundCooldown = Duration(seconds: 3);

  /// Check if pet can play sound (cooldown management)
  static bool canPlayPetSound(String petId) {
    final now = DateTime.now();
    final lastSound = _petSoundCooldowns[petId];
    if (lastSound == null) return true;
    return now.difference(lastSound) >= soundCooldown;
  }

  /// Mark that a pet sound was played
  static void markPetSoundPlayed(String petId) {
    _petSoundCooldowns[petId] = DateTime.now();
  }

  /// Play pet-specific sound with progressive fallback
  static Future<void> playPetSound(String petId) async {
    if (!canPlayPetSound(petId)) return;
    markPetSoundPlayed(petId);

    // Extract base animal name from pet ID
    String baseAnimalName = petId.replaceAll(RegExp(r'\d+'), '').toLowerCase();
    String soundPrefix = baseAnimalName[0].toUpperCase() + baseAnimalName.substring(1);
    
    // Handle special cases
    switch (baseAnimalName) {
      case 'axolotl':
        soundPrefix = 'Axolotl';
        break;
      case 'raccoon':
        soundPrefix = 'Raccoon';
        break;
      case 'sugar_glider':
        soundPrefix = 'SugarGlider';
        break;
      case 'honduran_bat':
        soundPrefix = 'HonduranBat';
        break;
    }
    
    // Progressive fallback: 1-20, 1-15, 1-10, 1-4
    final List<int> fallbackRanges = [20, 15, 10, 4];
    
    for (int range in fallbackRanges) {
      try {
        final random = DateTime.now().millisecondsSinceEpoch % range + 1;
        final soundFileName = '$soundPrefix$random.mp3';
        
        await _globalAudioPlayer.play(AssetSource('pets/pet_sounds/$soundFileName'));
        PetsDebugUtils.logAudio('Playing pet sound', 'pets/pet_sounds/$soundFileName (range 1-$range)', true);
        return;
        
      } catch (e) {
        PetsDebugUtils.logAudio('Failed to play sound', 'range 1-$range for $soundPrefix', false);
        continue;
      }
    }
    
    PetsDebugUtils.logError('playPetSound', 'Could not play any sound for pet: $petId (tried prefix: $soundPrefix)');
  }

  /// Create a properly configured PetState provider
  static ChangeNotifierProvider<PetState> createPetStateProvider({
    required Widget child,
    String? userId,
    required BuildContext context,
  }) {
    return ChangeNotifierProvider<PetState>(
      create: (context) => PetState(
        selectedPetId: 'cat', // Default pet
        petName: 'My Pet',
        selectedAccessory: 'None',
        isMuted: false,
        isEnabled: true,
        bondXP: 0,
        unlockedPets: ['cat', 'dog', 'bunny'],
        unlockedAccessories: [],
        onRewardEarned: userId != null ? (String rewardType, int amount, String reason) async {
          try {
            final rewardsManager = RewardsManager(Supabase.instance.client);
            
            if (rewardType == 'coins') {
              await rewardsManager.awardActivityCoins(userId, 'pet_reward', context, customAmount: amount);
            } else if (rewardType == 'points') {
              await rewardsManager.trackActivity(userId, 'pet_achievement', context, customPoints: amount);
            }
            
            // Show reward notification
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$reason: +$amount $rewardType'),
                  backgroundColor: rewardType == 'coins' ? Colors.amber : Colors.blue,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } catch (e) {
            PetsDebugUtils.logError('awardPetReward', e);
          }
        } : null,
      ),
      child: child,
    );
  }

  /// Initialize pet system with default configuration
  static Widget wrapWithPetSystem({
    required Widget child,
    String? userId,
    required BuildContext context,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PetState>(
          create: (context) => PetState(
            selectedPetId: 'cat',
            petName: 'My Pet',
            selectedAccessory: 'None',
            isMuted: false,
            isEnabled: true,
            bondXP: 0,
            unlockedPets: ['cat', 'dog', 'bunny'],
            unlockedAccessories: [],
            onRewardEarned: userId != null ? (String rewardType, int amount, String reason) async {
              try {
                final rewardsManager = RewardsManager(Supabase.instance.client);
                
                if (rewardType == 'coins') {
                  await rewardsManager.awardActivityCoins(userId, 'pet_reward', context, customAmount: amount);
                } else if (rewardType == 'points') {
                  await rewardsManager.trackActivity(userId, 'pet_achievement', context, customPoints: amount);
                }
                
                // Show reward notification
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$reason: +$amount $rewardType'),
                      backgroundColor: rewardType == 'coins' ? Colors.amber : Colors.blue,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                PetsDebugUtils.logError('awardPetReward', e);
              }
            } : null,
          ),
        ),
      ],
      child: child,
    );
  }

  /// Get pet by ID with error handling
  static Pet? getPetById(String petId) {
    return PetUtils.getPetById(petId);
  }

  /// Get all available pets
  static List<Pet> getAllPets() {
    return availablePets;
  }

  /// Get all available accessories
  static List<GlobalAccessory> getAllAccessories() {
    return globalAccessories;
  }

  /// Quick navigation to pet care screen
  static void navigateToPetCare(BuildContext context, {String? userId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetCareScreen(userId: userId),
      ),
    );
  }

  /// Quick navigation to pet details screen
  static void navigateToPetDetails(BuildContext context, {String? userId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailsScreen(userId: userId),
      ),
    );
  }

  /// Create an animated pet widget with consistent configuration
  static Widget createAnimatedPet({
    String? petId,
    String? petType,
    String? accessory,
    double size = 150,
    PetAction action = PetAction.idle,
    PetMood mood = PetMood.content,
    bool enableSounds = true,
    bool enableHaptics = true,
    bool enableParticles = true,
    Function()? onTap,
    Function()? onLongPress,
    double health = 100,
    double happiness = 100,
    double energy = 100,
  }) {
    return AnimatedPet(
      petId: petId,
      petType: petType,
      accessory: accessory,
      size: size,
      petAction: action,
      petMood: mood,
      enableSounds: enableSounds,
      enableHaptics: enableHaptics,
      enableParticles: enableParticles,
      onTap: onTap,
      onLongPress: onLongPress,
      health: health,
      happiness: happiness,
      energy: energy,
    );
  }

  /// Create a pet widget with message stream
  static Widget createPetWidget({
    required Stream<String> messageStream,
    String? userId,
    Function()? onPetTapped,
    Function()? onLevelUp,
    Function(String)? onPetSpeech,
    bool enableEmotions = true,
    bool enableRandomMovement = true,
  }) {
    return PetWidget(
      incomingMessages: messageStream,
      userId: userId,
      onPetTapped: onPetTapped,
      onLevelUp: onLevelUp,
      onPetSpeech: onPetSpeech,
      enableEmotions: enableEmotions,
      enableRandomMovement: enableRandomMovement,
    );
  }

  /// Dispose resources
  static void dispose() {
    _globalAudioPlayer.dispose();
    _petSoundCooldowns.clear();
  }
}

/// Extension methods for easier pet integration
extension PetStateExtensions on PetState {
  /// Get the current pet model
  Pet? get currentPet => PetUtils.getPetById(selectedPetId);
  
  /// Get the current accessory model
  GlobalAccessory? get currentAccessory {
    if (selectedAccessory == 'None') return null;
    return globalAccessories.where((acc) => acc.id == selectedAccessory).firstOrNull;
  }
  
  /// Get current pet's asset path with accessory
  String get currentPetAssetPath {
    final pet = currentPet;
    if (pet == null) return 'assets/pets/default.png';
    
    if (selectedAccessory != 'None') {
      return pet.getAssetPathWithAccessory(selectedAccessory);
    }
    return pet.assetPath;
  }
  
  /// Check if pet needs attention
  bool get needsAttention {
    return happiness < 0.5 || energy < 0.3 || health < 0.5;
  }
  
  /// Get overall wellbeing score
  double get overallWellbeing {
    return (happiness + energy + health) / 3.0;
  }
  
  /// Get current mood based on stats
  String get currentMood {
    if (happiness > 0.8 && energy > 0.7) return 'happy';
    if (happiness > 0.9) return 'excited';
    if (happiness < 0.3) return 'sad';
    if (energy < 0.3) return 'sleepy';
    if (health < 0.3) return 'sick';
    if (energy > 0.8) return 'energetic';
    return 'content';
  }
}

/// Integration constants
class PetIntegrationConstants {
  static const Duration soundCooldown = Duration(seconds: 3);
  static const Duration autoSaveInterval = Duration(minutes: 5);
  static const int maxBondLevel = 100;
  static const int xpPerLevel = 100;
  
  // Default pet configurations
  static const String defaultPetId = 'cat';
  static const String defaultPetName = 'My Pet';
  static const String defaultAccessory = 'None';
  
  // Sound paths
  static const String petSoundsPath = 'pets/pet_sounds';
  static const String gameSoundsPath = 'pets/sounds';
  
  // Asset paths
  static const String petsAssetsPath = 'assets/pets';
  static const String accessoriesPath = 'assets/pets/accessories';
}
