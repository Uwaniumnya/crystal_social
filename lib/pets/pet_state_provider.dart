// File: pet_state_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'updated_pet_list.dart';
import 'global_accessory_system.dart';

class PetState extends ChangeNotifier {
  // Core pet data
  String selectedPetId;
  String petName;
  String selectedAccessory;
  bool isMuted;
  bool isEnabled;
  int bondXP;
  int _lastKnownLevel;
  List<String> unlockedPets;
  List<String> unlockedAccessories; // Now stores global accessory IDs that are unlocked
  
  // Enhanced features
  DateTime? lastFed;
  DateTime? lastPlayed;
  double happiness;
  double energy;
  double health;
  int totalInteractions;
  Map<String, int> emotionHistory;
  List<String> achievements;
  Map<String, dynamic> petStats;
  bool enableNotifications;
  String currentMood;
  DateTime createdAt;
  DateTime lastActive;
  
  // Interaction tracking
  int dailyXPGained;
  DateTime lastXPReset;
  int longestStreak;
  int currentStreak;
  
  // Advanced features
  Map<String, bool> petPreferences;
  List<String> favoriteMessages;
  double petPersonality; // 0.0 = shy, 1.0 = outgoing
  
  // Loading and error states
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _autoSaveTimer;
  
  // Reward callback for currency and points
  Function(String rewardType, int amount, String reason)? onRewardEarned;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PetState({
    required this.selectedPetId,
    required this.petName,
    required this.selectedAccessory,
    required this.isMuted,
    required this.isEnabled,
    required this.bondXP,
    required this.unlockedPets,
    required this.unlockedAccessories,
    // Enhanced features with defaults
    this.lastFed,
    this.lastPlayed,
    this.happiness = 1.0,
    this.energy = 1.0,
    this.health = 1.0,
    this.totalInteractions = 0,
    Map<String, int>? emotionHistory,
    List<String>? achievements,
    Map<String, dynamic>? petStats,
    this.enableNotifications = true,
    this.currentMood = 'happy',
    DateTime? createdAt,
    DateTime? lastActive,
    this.dailyXPGained = 0,
    DateTime? lastXPReset,
    this.longestStreak = 0,
    this.currentStreak = 0,
    Map<String, bool>? petPreferences,
    List<String>? favoriteMessages,
    this.petPersonality = 0.5,
    this.onRewardEarned,
  }) : _lastKnownLevel = bondXP ~/ 100,
       emotionHistory = emotionHistory ?? <String, int>{},
       achievements = achievements ?? <String>[],
       petStats = petStats ?? <String, dynamic>{},
       createdAt = createdAt ?? DateTime.now(),
       lastActive = lastActive ?? DateTime.now(),
       lastXPReset = lastXPReset ?? DateTime.now(),
       petPreferences = petPreferences ?? <String, bool>{
         'enableRandomMovement': true,
         'enableEmotions': true,
         'enableSpeech': true,
         'enableParticleEffects': true,
       },
       favoriteMessages = favoriteMessages ?? <String>[] {
    _startAutoSave();
    _initializeStarterAccessories();
  }

  // Computed properties
  int get bondLevel => (bondXP ~/ 100);
  
  double get overallWellbeing => (happiness + energy + health) / 3.0;
  
  bool get needsAttention => 
      happiness < 0.3 || energy < 0.3 || health < 0.3;
  
  bool get isHappy => happiness > 0.7 && energy > 0.5;
  
  // Enhanced pet integration
  Pet? get currentPet => PetUtils.getPetById(selectedPetId);
  
  String get currentPetAssetPath {
    final pet = currentPet;
    if (pet == null) return 'assets/pets/cat.png'; // fallback
    
    // Use global accessory system
    if (selectedAccessory != 'None' && selectedAccessory.isNotEmpty) {
      final accessory = GlobalAccessoryUtils.getAccessoryById(selectedAccessory);
      if (accessory != null) {
        return accessory.getAssetPathForPet(pet.id, pet.assetPath);
      }
    }
    
    return pet.assetPath; // Return base asset if no accessory
  }
  
  List<String> get availableAccessoriesForCurrentPet {
    // Return all unlocked global accessories
    return unlockedAccessories;
  }
  
  List<GlobalAccessory> get availableAccessoryObjects {
    return GlobalAccessoryUtils.getOwnedAccessories(unlockedAccessories);
  }
  
  bool get canEquipAccessory {
    return unlockedAccessories.isNotEmpty;
  }
  
  String get petAge {
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    if (daysSinceCreation < 7) return 'Baby';
    if (daysSinceCreation < 30) return 'Young';
    if (daysSinceCreation < 100) return 'Adult';
    return 'Elder';
  }
  
  Map<String, dynamic> get detailedStats => {
    'level': bondLevel,
    'xp': bondXP,
    'happiness': happiness,
    'energy': energy,
    'health': health,
    'totalInteractions': totalInteractions,
    'daysSinceCreation': DateTime.now().difference(createdAt).inDays,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'wellbeing': overallWellbeing,
    'personality': petPersonality,
    'mood': currentMood,
  };

  static Future<PetState> loadFromSupabase(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_pets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create new pet state if none exists
        return _createDefaultPetState();
      }

      return PetState(
        selectedPetId: response['selected_pet_id'] ?? 'cat',
        petName: response['pet_name'] ?? 'My Pet',
        selectedAccessory: response['selected_accessory'] ?? 'None',
        isMuted: response['is_muted'] ?? false,
        isEnabled: response['is_enabled'] ?? true,
        bondXP: response['bond_xp'] ?? 0,
        unlockedPets: List<String>.from(response['unlocked_pets'] ?? ['cat', 'dog', 'bunny']),
        unlockedAccessories: List<String>.from(response['unlocked_accessories'] ?? []),
        // Enhanced features
        happiness: (response['happiness'] ?? 1.0).toDouble(),
        energy: (response['energy'] ?? 1.0).toDouble(),
        health: (response['health'] ?? 1.0).toDouble(),
        totalInteractions: response['total_interactions'] ?? 0,
        emotionHistory: Map<String, int>.from(response['emotion_history'] ?? {}),
        achievements: List<String>.from(response['achievements'] ?? []),
        petStats: Map<String, dynamic>.from(response['pet_stats'] ?? {}),
        enableNotifications: response['enable_notifications'] ?? true,
        currentMood: response['current_mood'] ?? 'happy',
        createdAt: response['created_at'] != null 
            ? DateTime.parse(response['created_at']) 
            : DateTime.now(),
        lastActive: response['last_active'] != null 
            ? DateTime.parse(response['last_active']) 
            : DateTime.now(),
        dailyXPGained: response['daily_xp_gained'] ?? 0,
        lastXPReset: response['last_xp_reset'] != null 
            ? DateTime.parse(response['last_xp_reset']) 
            : DateTime.now(),
        longestStreak: response['longest_streak'] ?? 0,
        currentStreak: response['current_streak'] ?? 0,
        petPreferences: Map<String, bool>.from(response['pet_preferences'] ?? {
          'enableRandomMovement': true,
          'enableEmotions': true,
          'enableSpeech': true,
          'enableParticleEffects': true,
        }),
        favoriteMessages: List<String>.from(response['favorite_messages'] ?? []),
        petPersonality: (response['pet_personality'] ?? 0.5).toDouble(),
        lastFed: response['last_fed'] != null 
            ? DateTime.parse(response['last_fed']) 
            : null,
        lastPlayed: response['last_played'] != null 
            ? DateTime.parse(response['last_played']) 
            : null,
      );
    } catch (e) {
      debugPrint('Error loading pet state: $e');
      return _createDefaultPetState();
    }
  }

  static PetState _createDefaultPetState() {
    return PetState(
      selectedPetId: 'cat',
      petName: 'My Pet',
      selectedAccessory: 'None',
      isMuted: false,
      isEnabled: true,
      bondXP: 0,
      unlockedPets: ['cat', 'dog', 'bunny'],
      unlockedAccessories: [],
    );
  }

  Future<void> saveToSupabase(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await Supabase.instance.client.from('user_pets').upsert({
        'user_id': userId,
        'selected_pet_id': selectedPetId,
        'pet_name': petName,
        'selected_accessory': selectedAccessory,
        'is_muted': isMuted,
        'is_enabled': isEnabled,
        'bond_xp': bondXP,
        'unlocked_pets': unlockedPets,
        'unlocked_accessories': unlockedAccessories,
        // Enhanced features
        'happiness': happiness,
        'energy': energy,
        'health': health,
        'total_interactions': totalInteractions,
        'emotion_history': emotionHistory,
        'achievements': achievements,
        'pet_stats': petStats,
        'enable_notifications': enableNotifications,
        'current_mood': currentMood,
        'created_at': createdAt.toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
        'daily_xp_gained': dailyXPGained,
        'last_xp_reset': lastXPReset.toIso8601String(),
        'longest_streak': longestStreak,
        'current_streak': currentStreak,
        'pet_preferences': petPreferences,
        'favorite_messages': favoriteMessages,
        'pet_personality': petPersonality,
        'last_fed': lastFed?.toIso8601String(),
        'last_played': lastPlayed?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      lastActive = DateTime.now();
    } catch (e) {
      _setError('Failed to save pet data: $e');
      debugPrint('Error saving pet state: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Enhanced update methods
  void updatePet({
    String? petId,
    String? name,
    String? accessory,
    bool? muted,
    bool? enabled,
  }) {
    if (petId != null) selectedPetId = petId;
    if (name != null) petName = name;
    if (accessory != null) selectedAccessory = accessory;
    if (muted != null) isMuted = muted;
    if (enabled != null) isEnabled = enabled;
    
    _updateLastActive();
    notifyListeners();
  }

  // Enhanced pet management methods
  void selectPet(String petId) {
    final pet = PetUtils.getPetById(petId);
    if (pet != null && unlockedPets.contains(petId)) {
      selectedPetId = petId;
      // Keep current accessory if it's unlocked, otherwise reset
      if (selectedAccessory != 'None' && !unlockedAccessories.contains(selectedAccessory)) {
        selectedAccessory = 'None';
      }
      _updateLastActive();
      notifyListeners();
    }
  }

  void equipAccessory(String accessoryId) {
    if (unlockedAccessories.contains(accessoryId)) {
      selectedAccessory = accessoryId;
      _updateLastActive();
      notifyListeners();
    }
  }

  void removeAccessory() {
    selectedAccessory = 'None';
    _updateLastActive();
    notifyListeners();
  }

  // Unlock a global accessory (called when purchased from shop)
  void unlockAccessory(String accessoryId) {
    if (!unlockedAccessories.contains(accessoryId)) {
      final accessory = GlobalAccessoryUtils.getAccessoryById(accessoryId);
      if (accessory != null) {
        unlockedAccessories.add(accessoryId);
        // Provide starter accessories for free
        if (accessory.shopPrice == 0) {
          achievements.add('unlocked_${accessoryId}');
        }
        _updateLastActive();
        notifyListeners();
      }
    }
  }

  // Check if user can unlock an accessory (always true for shop purchases)
  bool canUnlockAccessory(String accessoryId) {
    final accessory = GlobalAccessoryUtils.getAccessoryById(accessoryId);
    return accessory != null;
  }

  bool canUnlockPet(String petId) {
    // Since pets are now purchased from shop, they are unlocked when added to inventory
    // This method now just checks if pet exists
    final pet = PetUtils.getPetById(petId);
    return pet != null;
  }

  void unlockPet(String petId) {
    if (canUnlockPet(petId) && !unlockedPets.contains(petId)) {
      unlockedPets.add(petId);
      achievements.add('unlocked_${petId}');
      _updateLastActive();
      notifyListeners();
    }
  }

  List<Pet> get unlockedPetObjects {
    return PetUtils.getOwnedPets(unlockedPets);
  }

  List<Pet> get availableForPurchasePets {
    return PetUtils.getAvailableForPurchase(unlockedPets);
  }

  String getPetSpeech([String mood = 'neutral']) {
    final pet = currentPet;
    if (pet == null) return 'Hello!';
    return pet.getRandomSpeech(mood);
  }

  void feedPetWithFood(PetFood food) {
    final pet = currentPet;
    if (pet == null) return;
    
    lastFed = DateTime.now();
    
    // Enhanced feeding based on pet preferences
    double happinessMultiplier = 1.0;
    double healthMultiplier = 1.0;
    double energyMultiplier = 1.0;
    
    if (food.preferredBy.contains(pet.type)) {
      happinessMultiplier = 1.5;
      healthMultiplier = 1.3;
      energyMultiplier = 1.2;
    }
    
    updateStats(
      happinessChange: (food.happinessBoost / 100.0) * happinessMultiplier,
      energyChange: (food.energyBoost / 100.0) * energyMultiplier,
      healthChange: (food.healthBoost / 100.0) * healthMultiplier,
    );
    
    achievements.add('fed_${DateTime.now().millisecondsSinceEpoch}');
    _checkAchievements();
  }

  void updateStats({
    double? happinessChange,
    double? energyChange,
    double? healthChange,
  }) {
    if (happinessChange != null) {
      happiness = (happiness + happinessChange).clamp(0.0, 1.0);
    }
    if (energyChange != null) {
      energy = (energy + energyChange).clamp(0.0, 1.0);
    }
    if (healthChange != null) {
      health = (health + healthChange).clamp(0.0, 1.0);
    }
    
    _updateLastActive();
    notifyListeners();
  }

  void updateMood(String newMood) {
    currentMood = newMood;
    emotionHistory[newMood] = (emotionHistory[newMood] ?? 0) + 1;
    _updateLastActive();
    notifyListeners();
  }

  void updatePreference(String key, bool value) {
    petPreferences[key] = value;
    _updateLastActive();
    notifyListeners();
  }

  void increaseBondXP(int amount) {
    bondXP += amount;
    totalInteractions++;
    dailyXPGained += amount;
    
    // Update streak
    final today = DateTime.now();
    final daysSinceLastActive = today.difference(lastActive).inDays;
    
    if (daysSinceLastActive <= 1) {
      currentStreak++;
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
    } else {
      currentStreak = 1;
    }
    
    // Check for daily XP reset
    if (today.difference(lastXPReset).inDays >= 1) {
      dailyXPGained = amount;
      lastXPReset = today;
    }
    
    int newLevel = bondLevel;
    if (newLevel > _lastKnownLevel) {
      _lastKnownLevel = newLevel;
      _handleLevelUp(newLevel);
    }
    
    // Slight happiness boost from interaction
    updateStats(happinessChange: 0.02);
    _updateLastActive();
    notifyListeners();
  }

  void feedPet() {
    lastFed = DateTime.now();
    updateStats(
      happinessChange: 0.15,
      energyChange: 0.10,
      healthChange: 0.05,
    );
    achievements.add('fed_${DateTime.now().millisecondsSinceEpoch}');
    
    // Small coin reward for feeding
    onRewardEarned?.call('coins', 5, 'Fed pet');
    
    _checkAchievements();
  }

  void playWithPet() {
    lastPlayed = DateTime.now();
    updateStats(
      happinessChange: 0.20,
      energyChange: -0.05, // Playing costs energy
      healthChange: 0.02,
    );
    achievements.add('played_${DateTime.now().millisecondsSinceEpoch}');
    
    // Small coin reward for playing
    onRewardEarned?.call('coins', 8, 'Played with pet');
    
    _checkAchievements();
  }

  void addFavoriteMessage(String message) {
    if (!favoriteMessages.contains(message) && favoriteMessages.length < 10) {
      favoriteMessages.add(message);
      _updateLastActive();
      notifyListeners();
    }
  }

  void removeFavoriteMessage(String message) {
    favoriteMessages.remove(message);
    _updateLastActive();
    notifyListeners();
  }

  void _handleLevelUp(int level) {
    // Enhanced level up rewards - currency and main level points instead of pet unlocks
    int coinsReward = 0;
    int pointsReward = 0;
    String achievementName = '';
    
    if (level == 1) {
      achievements.add('first_level');
      coinsReward = 50;
      pointsReward = 25;
      achievementName = 'First Pet Level';
    }
    if (level == 5) {
      achievements.add('level_5_milestone');
      coinsReward = 100;
      pointsReward = 50;
      achievementName = 'Pet Level 5 Milestone';
    }
    if (level == 10) {
      achievements.add('level_10_milestone');
      coinsReward = 200;
      pointsReward = 100;
      achievementName = 'Pet Level 10 Milestone';
    }
    if (level == 15) {
      achievements.add('level_15_milestone');
      coinsReward = 300;
      pointsReward = 150;
      achievementName = 'Pet Level 15 Milestone';
    }
    if (level == 20) {
      achievements.add('master_pet_trainer');
      coinsReward = 500;
      pointsReward = 250;
      achievementName = 'Master Pet Trainer';
    }
    if (level == 25) {
      achievements.add('dragon_master');
      coinsReward = 750;
      pointsReward = 375;
      achievementName = 'Dragon Master';
    }
    if (level == 50) {
      achievements.add('legendary_bond_achievement');
      coinsReward = 1500;
      pointsReward = 750;
      achievementName = 'Legendary Bond';
    }
    if (level == 75) {
      achievements.add('pure_heart_achievement');
      coinsReward = 2500;
      pointsReward = 1250;
      achievementName = 'Pure Heart Bond';
    }
    if (level == 100) {
      achievements.add('bond_level_100');
      coinsReward = 5000;
      pointsReward = 2500;
      achievementName = 'Ultimate Pet Bond';
    }
    
    // Award currency and points for level up
    if (coinsReward > 0) {
      onRewardEarned?.call('coins', coinsReward, 'Pet Level Up: $achievementName');
    }
    if (pointsReward > 0) {
      onRewardEarned?.call('points', pointsReward, 'Pet Level Up: $achievementName');
    }
    
    // Boost stats on level up
    updateStats(
      happinessChange: 0.3,
      energyChange: 0.2,
      healthChange: 0.1,
    );
    
    _checkAchievements();
  }

  // Helper methods
  void _updateLastActive() {
    lastActive = DateTime.now();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      // Auto-save would need userId context, so this is placeholder
      // In practice, the parent widget should handle periodic saves
    });
  }

  void _initializeStarterAccessories() {
    // Add free starter accessories if this is a new pet state
    final starterAccessories = GlobalAccessoryUtils.getStarterAccessories();
    for (final accessory in starterAccessories) {
      if (!unlockedAccessories.contains(accessory.id)) {
        unlockedAccessories.add(accessory.id);
      }
    }
  }

  void _checkAchievements() {
    // Check for various achievements and award currency/points instead of unlocks
    if (totalInteractions >= 100 && !achievements.contains('socialite')) {
      achievements.add('socialite');
      onRewardEarned?.call('coins', 300, 'Pet Achievement: Socialite (100 interactions)');
      onRewardEarned?.call('points', 150, 'Pet Achievement: Socialite (100 interactions)');
    }
    if (currentStreak >= 7 && !achievements.contains('week_streak')) {
      achievements.add('week_streak');
      onRewardEarned?.call('coins', 200, 'Pet Achievement: Week Streak (7 days)');
      onRewardEarned?.call('points', 100, 'Pet Achievement: Week Streak (7 days)');
    }
    if (currentStreak >= 30 && !achievements.contains('month_streak')) {
      achievements.add('month_streak');
      onRewardEarned?.call('coins', 800, 'Pet Achievement: Month Streak (30 days)');
      onRewardEarned?.call('points', 400, 'Pet Achievement: Month Streak (30 days)');
    }
    if (happiness >= 0.9 && energy >= 0.9 && health >= 0.9 && !achievements.contains('perfect_care')) {
      achievements.add('perfect_care');
      onRewardEarned?.call('coins', 400, 'Pet Achievement: Perfect Care (90%+ all stats)');
      onRewardEarned?.call('points', 200, 'Pet Achievement: Perfect Care (90%+ all stats)');
    }
    if (unlockedPets.length >= 3 && !achievements.contains('pet_collector')) {
      achievements.add('pet_collector');
      onRewardEarned?.call('coins', 500, 'Pet Achievement: Pet Collector (3+ pets)');
      onRewardEarned?.call('points', 250, 'Pet Achievement: Pet Collector (3+ pets)');
    }
    if (bondLevel >= 50 && !achievements.contains('pet_master')) {
      achievements.add('pet_master');
      onRewardEarned?.call('coins', 1000, 'Pet Achievement: Pet Master (Level 50)');
      onRewardEarned?.call('points', 500, 'Pet Achievement: Pet Master (Level 50)');
    }
  }

  // Maintenance methods
  void performDailyMaintenance() {
    final now = DateTime.now();
    final hoursSinceLastActive = now.difference(lastActive).inHours;
    
    // Gradual stat decay if pet hasn't been interacted with
    if (hoursSinceLastActive > 12) {
      final decayAmount = (hoursSinceLastActive - 12) * 0.01;
      updateStats(
        happinessChange: -decayAmount,
        energyChange: -decayAmount * 0.5,
        healthChange: -decayAmount * 0.3,
      );
    }
    
    // Reset daily XP if needed
    if (now.difference(lastXPReset).inDays >= 1) {
      dailyXPGained = 0;
      lastXPReset = now;
    }
    
    // Check streak
    if (now.difference(lastActive).inDays > 1) {
      currentStreak = 0;
    }
  }

  void resetPet() {
    happiness = 1.0;
    energy = 1.0;
    health = 1.0;
    currentMood = 'happy';
    emotionHistory.clear();
    _updateLastActive();
    notifyListeners();
  }

  // Data export/import for backup
  Map<String, dynamic> exportData() {
    return {
      'selectedPetId': selectedPetId,
      'petName': petName,
      'selectedAccessory': selectedAccessory,
      'isMuted': isMuted,
      'isEnabled': isEnabled,
      'bondXP': bondXP,
      'unlockedPets': unlockedPets,
      'unlockedAccessories': unlockedAccessories,
      'happiness': happiness,
      'energy': energy,
      'health': health,
      'totalInteractions': totalInteractions,
      'emotionHistory': emotionHistory,
      'achievements': achievements,
      'petStats': petStats,
      'enableNotifications': enableNotifications,
      'currentMood': currentMood,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'dailyXPGained': dailyXPGained,
      'lastXPReset': lastXPReset.toIso8601String(),
      'longestStreak': longestStreak,
      'currentStreak': currentStreak,
      'petPreferences': petPreferences,
      'favoriteMessages': favoriteMessages,
      'petPersonality': petPersonality,
      'lastFed': lastFed?.toIso8601String(),
      'lastPlayed': lastPlayed?.toIso8601String(),
    };
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
