// File: enhanced_pet_list.dart

import 'package:flutter/material.dart';

// Enhanced enums for pet characteristics
enum PetType { cat, dog, bunny, axolotl, dragon, phoenix, unicorn, griffin, fox, wolf }
enum PetRarity { common, uncommon, rare, epic, legendary, mythical }
enum PetPersonality { playful, calm, energetic, lazy, friendly, shy, brave, mischievous }
enum FoodCategory { drinks, fruits_and_vegetables, meals, meat, sweets }

class PetFood {
  final String name;
  final String assetPath;
  final FoodCategory category;
  final int healthBoost;
  final int happinessBoost;
  final int energyBoost;
  final List<PetType> preferredBy;
  final PetRarity rarity;
  final String description;
  final double price;

  const PetFood({
    required this.name,
    required this.assetPath,
    required this.category,
    required this.healthBoost,
    required this.happinessBoost,
    required this.energyBoost,
    required this.preferredBy,
    required this.rarity,
    required this.description,
    this.price = 10.0,
  });

  // Helper methods
  String get categoryDisplayName => category.name.toUpperCase();
  Color get categoryColor {
    switch (category) {
      case FoodCategory.drinks:
        return Colors.blue;
      case FoodCategory.fruits_and_vegetables:
        return Colors.green;
      case FoodCategory.meals:
        return Colors.orange;
      case FoodCategory.meat:
        return Colors.red;
      case FoodCategory.sweets:
        return Colors.pink;
    }
  }
}

class Pet {
  final String id;
  final String name;
  final String assetPath;
  final List<String> speechLines;
  final PetType type;
  final PetRarity rarity;
  final PetPersonality personality;
  final List<String> favoriteActivities;
  final List<String> dislikedActivities;
  final List<PetFood> favoriteFoods;
  final Map<String, String> moodSpeech;
  final String description;
  final String lore;
  final double shopPrice; // Price in the shop
  final String shopCategory; // Category for shop display (e.g., 'pet', 'premium_pet')

  const Pet({
    required this.id,
    required this.name,
    required this.assetPath,
    this.speechLines = const [],
    required this.type,
    required this.rarity,
    required this.personality,
    this.favoriteActivities = const [],
    this.dislikedActivities = const [],
    this.favoriteFoods = const [],
    this.moodSpeech = const {},
    required this.description,
    this.lore = '',
    this.shopPrice = 100.0, // Default price
    this.shopCategory = 'pet',
  });

  // Helper methods
  bool get isLegendary => rarity == PetRarity.legendary || rarity == PetRarity.mythical;
  String get rarityDisplayName => rarity.name.toUpperCase();
  
  // Get asset path for pet with global accessory applied
  String getAssetPathWithAccessory(String? accessoryId) {
    if (accessoryId == null || accessoryId == 'None') {
      return assetPath; // Return base asset if no accessory
    }
    
    // Modify the asset path to include the accessory
    // Example: assets/pets/pets/real/cat/cat.png -> assets/pets/pets/real/cat/cat_bow.png
    final basePath = assetPath.replaceAll('.png', '');
    return '${basePath}_${accessoryId.toLowerCase()}.png';
  }
  
  // Get random speech line based on mood
  String getRandomSpeech([String mood = 'neutral']) {
    if (moodSpeech.containsKey(mood)) {
      return moodSpeech[mood]!;
    }
    if (speechLines.isNotEmpty) {
      return speechLines[(speechLines.length * DateTime.now().millisecond / 1000).floor() % speechLines.length];
    }
    return 'Hello!';
  }

  // Check if pet likes specific activity
  bool likesActivity(String activity) => favoriteActivities.contains(activity);
  bool dislikesActivity(String activity) => dislikedActivities.contains(activity);
}

// Enhanced pet list with comprehensive data from real asset folder
final List<Pet> availablePets = [
  // Cats - Multiple variants
  Pet(
    id: 'cat',
    name: 'Whiskers',
    assetPath: 'assets/pets/pets/real/cat/cat.png',
    speechLines: ['Meow!', 'Purr...', 'Feed me!', 'Pet me!', 'I love you!'],
    type: PetType.cat,
    rarity: PetRarity.common,
    personality: PetPersonality.friendly,
    favoriteActivities: ['petting', 'playing', 'sleeping'],
    dislikedActivities: ['bathing', 'loud_noises'],
    moodSpeech: {
      'happy': 'Purr purr! 😸',
      'sad': 'Meow... 😿',
      'angry': 'Hiss! 😾',
      'sleepy': 'Yawn... meow... 😴',
      'playful': 'Meow! Play with me! 🎾',
    },
    description: 'A friendly and affectionate cat that loves attention and cuddles.',
    lore: 'Once a street cat who found warmth in human kindness, now a loyal companion.',
    shopPrice: 100.0,
  ),
  // Dogs - Multiple variants
  Pet(
    id: 'dog',
    name: 'Buddy',
    assetPath: 'assets/pets/pets/real/dog/dog.png',
    speechLines: ['Woof!', 'Good boy!', 'Let\'s play!', 'I love walks!'],
    type: PetType.dog,
    rarity: PetRarity.common,
    personality: PetPersonality.friendly,
    favoriteActivities: ['walking', 'fetching', 'playing'],
    dislikedActivities: ['being_alone', 'storms'],
    moodSpeech: {
      'happy': 'Wag wag! Arf! 🐕',
      'sad': 'Whimper... 😢',
      'angry': 'Growl! 😤',
      'sleepy': 'Yawn... zzz... 😴',
      'playful': 'Arf arf! Let\'s play! 🎾',
    },
    description: 'A loyal and energetic dog that loves companionship.',
    lore: 'A faithful companion who brings joy wherever he goes.',
    shopPrice: 150.0,
  ),


  // Bunnies - Multiple variants
  Pet(
    id: 'bunny',
    name: 'Cotton',
    assetPath: 'assets/pets/pets/real/bunny/bunny.png',
    speechLines: ['Hop hop!', 'Carrot?', 'Binky time!', 'Sniff sniff', 'Boing!'],
    type: PetType.bunny,
    rarity: PetRarity.common,
    personality: PetPersonality.playful,
    favoriteActivities: ['hopping', 'eating', 'exploring'],
    dislikedActivities: ['loud_noises', 'being_picked_up'],
    moodSpeech: {
      'happy': 'Binky! Hop hop! 🐰',
      'sad': 'Soft whimper... 😢',
      'angry': 'Thump thump! 😤',
      'sleepy': 'Zzz... twitch... 😴',
      'playful': 'Boing boing! Chase me! 🏃‍♂️',
    },
    description: 'An energetic bunny that loves to hop around and explore new places.',
    lore: 'Born under a full moon, this bunny brings joy wherever it hops.',
    shopPrice: 200.0,
  ),


  // Axolotl
  Pet(
    id: 'axolotl',
    name: 'Bubbles',
    assetPath: 'assets/pets/pets/real/axelotl/axelotl.png',
    speechLines: ['Blub blub', 'Swimming...', 'Regenerating!', 'Aquatic life!', 'Underwater cutie'],
    type: PetType.axolotl,
    rarity: PetRarity.rare,
    personality: PetPersonality.calm,
    favoriteActivities: ['swimming', 'resting', 'meditation'],
    dislikedActivities: ['dry_environments', 'stress'],
    moodSpeech: {
      'happy': 'Blub blub! *happy wiggle* 🌊',
      'sad': 'Sad bubbles... 💧',
      'angry': 'Aggressive gill fluttering! 😠',
      'sleepy': 'Floating dreams... 💤',
      'playful': 'Underwater dance! 💃',
    },
    description: 'A mystical axolotl with incredible regenerative abilities.',
    lore: 'Ancient guardians of underwater realms, known for their healing powers.',
    shopPrice: 800.0,
  ),

  // Fox
  Pet(
    id: 'fox',
    name: 'Foxy',
    assetPath: 'assets/pets/pets/real/fox/fox.png',
    speechLines: ['Yip yip!', 'Clever fox!', 'Mischief time!', 'So sneaky!', 'Fox magic!'],
    type: PetType.fox,
    rarity: PetRarity.rare,
    personality: PetPersonality.mischievous,
    favoriteActivities: ['exploring', 'puzzle_solving', 'night_walks'],
    dislikedActivities: ['water', 'being_ignored'],
    moodSpeech: {
      'happy': 'Yip yip! *tail wag* 🦊',
      'sad': 'Whimper... *ears down* 😢',
      'angry': 'Angry yip! *fur bristled* 😡',
      'sleepy': 'Curled up zzz... 🌙',
      'playful': 'Pounce! Let\'s play! 🎮',
    },
    description: 'A clever and mischievous fox with ice-like fur patterns.',
    lore: 'Born from forest blizzards, this fox brings both wisdom and playful chaos.',
    shopPrice: 500.0,
  ),

  // New Real Animals
  Pet(
    id: 'panda',
    name: 'Bamboo',
    assetPath: 'assets/pets/pets/real/panda/panda.png',
    speechLines: ['Munch munch', 'Bamboo please!', 'Rolling around', 'Lazy day'],
    type: PetType.unicorn, // Using unicorn enum as placeholder for panda
    rarity: PetRarity.epic,
    personality: PetPersonality.lazy,
    favoriteActivities: ['eating_bamboo', 'rolling', 'sleeping'],
    dislikedActivities: ['fast_movement', 'loud_noises'],
    description: 'An adorable panda that loves bamboo and rolling around.',
    lore: 'Symbol of peace and tranquility, this panda brings calm energy.',
    shopPrice: 1500.0,
  ),

  Pet(
    id: 'penguin',
    name: 'Waddles',
    assetPath: 'assets/pets/pets/real/penguin/penguin.png',
    speechLines: ['Squawk!', 'Slide on ice!', 'Fish time!', 'Waddle waddle'],
    type: PetType.griffin, // Using griffin enum as placeholder
    rarity: PetRarity.rare,
    personality: PetPersonality.playful,
    favoriteActivities: ['swimming', 'sliding', 'fish_hunting'],
    dislikedActivities: ['warm_weather', 'dry_land'],
    description: 'A charming penguin that loves ice and fish.',
    lore: 'From the icy lands, this penguin brings arctic magic.',
    shopPrice: 600.0,
  ),

  Pet(
    id: 'raccoon',
    name: 'Bandit',
    assetPath: 'assets/pets/pets/real/racoon/racoon.png',
    speechLines: ['Chittering', 'Shiny things!', 'Wash wash', 'Midnight raid'],
    type: PetType.wolf, // Using wolf enum as placeholder
    rarity: PetRarity.uncommon,
    personality: PetPersonality.mischievous,
    favoriteActivities: ['foraging', 'collecting', 'washing_food'],
    dislikedActivities: ['daylight', 'empty_hands'],
    description: 'A clever raccoon with a mask-like face and nimble paws.',
    lore: 'Master of midnight adventures and collector of treasures.',
    shopPrice: 300.0,
  ),

  Pet(
    id: 'elephant',
    name: 'Trunk',
    assetPath: 'assets/pets/pets/real/elephant/elephant.png',
    speechLines: ['Trumpet!', 'Never forget', 'Gentle giant', 'Memory keeper'],
    type: PetType.dragon, // Using dragon enum as placeholder
    rarity: PetRarity.legendary,
    personality: PetPersonality.calm,
    favoriteActivities: ['remembering', 'protecting', 'water_bathing'],
    dislikedActivities: ['forgetting', 'being_rushed'],
    description: 'A wise elephant with an incredible memory.',
    lore: 'Ancient keeper of memories and guardian of wisdom.',
    shopPrice: 5000.0,
  ),

  Pet(
    id: 'hedgehog',
    name: 'Spike',
    assetPath: 'assets/pets/pets/real/hedgehog/hedgehog.png',
    speechLines: ['Snort snort', 'Roll up!', 'Prickly but cute', 'Night explorer'],
    type: PetType.fox, // Using fox enum as placeholder
    rarity: PetRarity.uncommon,
    personality: PetPersonality.shy,
    favoriteActivities: ['rolling_up', 'foraging', 'hiding'],
    dislikedActivities: ['predators', 'bright_lights'],
    description: 'A small hedgehog with protective spines and a gentle heart.',
    lore: 'Guardian of garden secrets and midnight wanderer.',
    shopPrice: 250.0,
  ),

  Pet(
    id: 'koala',
    name: 'Sleepy',
    assetPath: 'assets/pets/pets/real/koala/koala.png',
    speechLines: ['Zzz...', 'Eucalyptus...', 'Just five more minutes', 'Sleepy time'],
    type: PetType.unicorn, // Using unicorn enum as placeholder
    rarity: PetRarity.rare,
    personality: PetPersonality.lazy,
    favoriteActivities: ['sleeping', 'eating_eucalyptus', 'tree_hugging'],
    dislikedActivities: ['being_woken_up', 'activity'],
    description: 'A drowsy koala that spends most of its time sleeping.',
    lore: 'Dream keeper of the eucalyptus forests.',
    shopPrice: 700.0,
  ),

  Pet(
    id: 'otter',
    name: 'Splash',
    assetPath: 'assets/pets/pets/real/otter/otter.png',
    speechLines: ['Squeaky!', 'Dive time!', 'Shell cracking', 'Float together'],
    type: PetType.axolotl, // Using axolotl enum as similar aquatic
    rarity: PetRarity.rare,
    personality: PetPersonality.playful,
    favoriteActivities: ['swimming', 'diving', 'floating'],
    dislikedActivities: ['dry_land', 'being_alone'],
    description: 'A playful otter that loves water and floating on its back.',
    lore: 'Master of river games and aquatic acrobatics.',
    shopPrice: 650.0,
  ),

  Pet(
    id: 'deer',
    name: 'Grace',
    assetPath: 'assets/pets/pets/real/deer/deer.png',
    speechLines: ['Gentle snort', 'Forest whisper', 'Graceful bound', 'Nature\'s child'],
    type: PetType.unicorn, // Using unicorn enum as closest magical creature
    rarity: PetRarity.epic,
    personality: PetPersonality.calm,
    favoriteActivities: ['grazing', 'forest_walks', 'leaping'],
    dislikedActivities: ['hunters', 'loud_noises'],
    description: 'An elegant deer with graceful movements and gentle eyes.',
    lore: 'Spirit of the forest, bringing peace and natural magic.',
    shopPrice: 1200.0,
  ),

  Pet(
    id: 'dolphin',
    name: 'Echo',
    assetPath: 'assets/pets/pets/real/dolphin/dolphin.png',
    speechLines: ['Click click!', 'Sonar ping', 'Jump high!', 'Ocean song'],
    type: PetType.axolotl, // Using axolotl enum for aquatic
    rarity: PetRarity.legendary,
    personality: PetPersonality.friendly,
    favoriteActivities: ['jumping', 'echolocation', 'socializing'],
    dislikedActivities: ['shallow_water', 'captivity'],
    description: 'An intelligent dolphin with remarkable communication abilities.',
    lore: 'Ocean\'s messenger, bridging the world between land and sea.',
    shopPrice: 3000.0,
  ),

  Pet(
    id: 'seal',
    name: 'Flipper',
    assetPath: 'assets/pets/pets/real/seal/seal.png',
    speechLines: ['Bark bark!', 'Clap clap', 'Fish please!', 'Sunbathing'],
    type: PetType.axolotl, // Using axolotl enum for aquatic
    rarity: PetRarity.uncommon,
    personality: PetPersonality.playful,
    favoriteActivities: ['swimming', 'sunbathing', 'clapping'],
    dislikedActivities: ['cold_weather', 'no_fish'],
    description: 'A friendly seal that loves to perform and play.',
    lore: 'Entertainer of the seas, bringing joy to coastal waters.',
    shopPrice: 400.0,
  ),

  Pet(
    id: 'octopus',
    name: 'Inky',
    assetPath: 'assets/pets/pets/real/octopus/octopus.png',
    speechLines: ['Gurgle', 'Eight arms ready!', 'Color change', 'Hidden treasure'],
    type: PetType.axolotl, // Using axolotl enum for aquatic
    rarity: PetRarity.epic,
    personality: PetPersonality.mischievous,
    favoriteActivities: ['hiding', 'color_changing', 'puzzle_solving'],
    dislikedActivities: ['bright_lights', 'open_spaces'],
    description: 'A clever octopus with color-changing abilities.',
    lore: 'Master of disguise and keeper of ocean mysteries.',
    shopPrice: 1800.0,
  ),

  // Additional Real Animals
  Pet(
    id: 'rat',
    name: 'Squeaky',
    assetPath: 'assets/pets/pets/real/rat/rat.png',
    speechLines: ['Squeak squeak!', 'Cheese please!', 'Scurry time!', 'Quick and clever'],
    type: PetType.fox, // Using fox enum as placeholder for small mammal
    rarity: PetRarity.common,
    personality: PetPersonality.energetic,
    favoriteActivities: ['exploring', 'foraging', 'hiding'],
    dislikedActivities: ['cats', 'loud_noises'],
    description: 'A clever little rat with boundless energy and curiosity.',
    lore: 'Street-smart survivor who knows every secret passage.',
    shopPrice: 80.0,
  ),

  Pet(
    id: 'sugar_glider001',
    name: 'Glide',
    assetPath: 'assets/pets/pets/real/sugar_glider/sugar_glider.png',
    speechLines: ['Chirp chirp!', 'Gliding time!', 'Sweet treats!', 'Night flight'],
    type: PetType.fox, // Using fox enum as placeholder
    rarity: PetRarity.rare,
    personality: PetPersonality.playful,
    favoriteActivities: ['gliding', 'climbing', 'socializing'],
    dislikedActivities: ['being_alone', 'daylight'],
    description: 'An adorable sugar glider that loves to glide from tree to tree.',
    lore: 'Nocturnal acrobat of the forest canopy.',
    shopPrice: 900.0,
  ),

  Pet(
    id: 'fennec',
    name: 'Sandy',
    assetPath: 'assets/pets/pets/real/fennec/fennec.png',
    speechLines: ['Yip!', 'Desert winds!', 'Big ears, big heart!', 'Sand runner'],
    type: PetType.fox, // Perfect match for fennec fox
    rarity: PetRarity.rare,
    personality: PetPersonality.energetic,
    favoriteActivities: ['digging', 'night_hunting', 'listening'],
    dislikedActivities: ['cold_weather', 'water'],
    description: 'A tiny fennec fox with enormous ears and desert wisdom.',
    lore: 'Guardian of the desert sands, master of survival.',
    shopPrice: 750.0,
  ),

  Pet(
    id: 'honduran_bat001',
    name: 'Echo',
    assetPath: 'assets/pets/pets/real/honduran_bat/honduran_bat.png',
    speechLines: ['Screech!', 'Echolocation!', 'Night flight!', 'Fruit finder'],
    type: PetType.griffin, // Using griffin enum as placeholder for flying creature
    rarity: PetRarity.uncommon,
    personality: PetPersonality.shy,
    favoriteActivities: ['flying', 'hanging_upside_down', 'fruit_eating'],
    dislikedActivities: ['bright_lights', 'loud_noises'],
    description: 'A gentle fruit bat with excellent night vision.',
    lore: 'Nighttime navigator and fruit forest guardian.',
    shopPrice: 350.0,
  ),

  Pet(
    id: 'cheetah',
    name: 'Dash',
    assetPath: 'assets/pets/pets/real/cheetah/cheetah.png',
    speechLines: ['Fast as lightning!', 'Speed demon!', 'Spotted beauty!', 'Race time!'],
    type: PetType.cat, // Closest relative to cheetah
    rarity: PetRarity.epic,
    personality: PetPersonality.energetic,
    favoriteActivities: ['running', 'hunting', 'sunbathing'],
    dislikedActivities: ['slow_movement', 'cold_weather'],
    description: 'The fastest land animal with beautiful spotted fur.',
    lore: 'Born to run, master of speed and grace.',
    shopPrice: 2500.0,
  ),

  Pet(
    id: 'snake',
    name: 'Slither',
    assetPath: 'assets/pets/pets/real/snake/snake.png',
    speechLines: ['Hissss...', 'Silent hunter', 'Smooth scales', 'Serpent wisdom'],
    type: PetType.dragon, // Using dragon enum as closest reptilian match
    rarity: PetRarity.rare,
    personality: PetPersonality.calm,
    favoriteActivities: ['sunbathing', 'hiding', 'meditation'],
    dislikedActivities: ['cold_weather', 'being_handled'],
    description: 'A graceful snake with hypnotic movements.',
    lore: 'Ancient symbol of wisdom and transformation.',
    shopPrice: 850.0,
  ),
];

// Pet food definitions organized by asset folder structure
final List<PetFood> availableFoods = [
  // Drinks Category
  const PetFood(
    name: 'Fresh Water',
    assetPath: 'assets/pets/food/drinks/water.png',
    category: FoodCategory.drinks,
    healthBoost: 5,
    happinessBoost: 3,
    energyBoost: 10,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny, PetType.axolotl, PetType.fox, PetType.wolf],
    rarity: PetRarity.common,
    description: 'Clean, refreshing water essential for all pets.',
    price: 1.0,
  ),
  const PetFood(
    name: 'Milk',
    assetPath: 'assets/pets/food/drinks/milk.png',
    category: FoodCategory.drinks,
    healthBoost: 8,
    happinessBoost: 12,
    energyBoost: 5,
    preferredBy: [PetType.cat, PetType.dog],
    rarity: PetRarity.common,
    description: 'Creamy milk that cats and dogs love.',
    price: 3.0,
  ),
  const PetFood(
    name: 'Milk Carton',
    assetPath: 'assets/pets/food/drinks/milk_carton.png',
    category: FoodCategory.drinks,
    healthBoost: 10,
    happinessBoost: 15,
    energyBoost: 8,
    preferredBy: [PetType.cat, PetType.dog],
    rarity: PetRarity.common,
    description: 'Fresh milk in a convenient carton.',
    price: 4.0,
  ),
  const PetFood(
    name: 'Chocolate Milk',
    assetPath: 'assets/pets/food/drinks/choco_milk.png',
    category: FoodCategory.drinks,
    healthBoost: 12,
    happinessBoost: 25,
    energyBoost: 15,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny],
    rarity: PetRarity.uncommon,
    description: 'Sweet chocolate milk that pets enjoy as a treat.',
    price: 6.0,
  ),
  const PetFood(
    name: 'Orange Juice',
    assetPath: 'assets/pets/food/drinks/orange_juice.png',
    category: FoodCategory.drinks,
    healthBoost: 6,
    happinessBoost: 18,
    energyBoost: 20,
    preferredBy: [PetType.bunny, PetType.fox],
    rarity: PetRarity.common,
    description: 'Fresh squeezed orange juice packed with vitamins.',
    price: 5.0,
  ),
  const PetFood(
    name: 'Soda',
    assetPath: 'assets/pets/food/drinks/soda.png',
    category: FoodCategory.drinks,
    healthBoost: 2,
    happinessBoost: 30,
    energyBoost: 35,
    preferredBy: [PetType.fox, PetType.wolf],
    rarity: PetRarity.uncommon,
    description: 'Fizzy soda drink that provides quick energy.',
    price: 8.0,
  ),
  const PetFood(
    name: 'Tea',
    assetPath: 'assets/pets/food/drinks/tea.png',
    category: FoodCategory.drinks,
    healthBoost: 8,
    happinessBoost: 20,
    energyBoost: 12,
    preferredBy: [PetType.cat, PetType.unicorn],
    rarity: PetRarity.common,
    description: 'Soothing herbal tea with calming properties.',
    price: 7.0,
  ),
  const PetFood(
    name: 'Coffee',
    assetPath: 'assets/pets/food/drinks/coffee.png',
    category: FoodCategory.drinks,
    healthBoost: 5,
    happinessBoost: 15,
    energyBoost: 40,
    preferredBy: [PetType.dragon, PetType.phoenix],
    rarity: PetRarity.uncommon,
    description: 'Strong coffee that boosts energy levels.',
    price: 10.0,
  ),
  const PetFood(
    name: 'Latte Macchiato',
    assetPath: 'assets/pets/food/drinks/latte_machiatto.png',
    category: FoodCategory.drinks,
    healthBoost: 8,
    happinessBoost: 25,
    energyBoost: 30,
    preferredBy: [PetType.dragon, PetType.phoenix, PetType.unicorn],
    rarity: PetRarity.rare,
    description: 'Premium coffee drink with steamed milk.',
    price: 15.0,
  ),
  const PetFood(
    name: 'Cream Coffee',
    assetPath: 'assets/pets/food/drinks/cream_coffee.png',
    category: FoodCategory.drinks,
    healthBoost: 10,
    happinessBoost: 22,
    energyBoost: 35,
    preferredBy: [PetType.dragon, PetType.phoenix],
    rarity: PetRarity.uncommon,
    description: 'Rich coffee with cream for extra smoothness.',
    price: 12.0,
  ),
  const PetFood(
    name: 'Matcha',
    assetPath: 'assets/pets/food/drinks/macha.png',
    category: FoodCategory.drinks,
    healthBoost: 15,
    happinessBoost: 20,
    energyBoost: 25,
    preferredBy: [PetType.cat, PetType.unicorn, PetType.dragon],
    rarity: PetRarity.rare,
    description: 'Traditional matcha tea with antioxidants.',
    price: 18.0,
  ),
  const PetFood(
    name: 'Boba Tea',
    assetPath: 'assets/pets/food/drinks/boba.png',
    category: FoodCategory.drinks,
    healthBoost: 12,
    happinessBoost: 40,
    energyBoost: 28,
    preferredBy: [PetType.bunny, PetType.fox, PetType.unicorn],
    rarity: PetRarity.rare,
    description: 'Fun bubble tea with chewy tapioca pearls.',
    price: 20.0,
  ),
  const PetFood(
    name: 'Energy Drink',
    assetPath: 'assets/pets/food/drinks/drink.png',
    category: FoodCategory.drinks,
    healthBoost: 10,
    happinessBoost: 20,
    energyBoost: 50,
    preferredBy: [PetType.dragon, PetType.phoenix, PetType.griffin],
    rarity: PetRarity.rare,
    description: 'High-energy drink for magical creatures.',
    price: 25.0,
  ),
  const PetFood(
    name: 'Beer',
    assetPath: 'assets/pets/food/drinks/beer.png',
    category: FoodCategory.drinks,
    healthBoost: 3,
    happinessBoost: 35,
    energyBoost: 8,
    preferredBy: [PetType.wolf, PetType.fox],
    rarity: PetRarity.epic,
    description: 'Frothy beer for adult pets only.',
    price: 30.0,
  ),
  const PetFood(
    name: 'Wine',
    assetPath: 'assets/pets/food/drinks/wine.png',
    category: FoodCategory.drinks,
    healthBoost: 5,
    happinessBoost: 45,
    energyBoost: 10,
    preferredBy: [PetType.dragon, PetType.phoenix, PetType.unicorn],
    rarity: PetRarity.epic,
    description: 'Fine wine for sophisticated magical beings.',
    price: 50.0,
  ),
  const PetFood(
    name: 'Sake',
    assetPath: 'assets/pets/food/drinks/sake.png',
    category: FoodCategory.drinks,
    healthBoost: 8,
    happinessBoost: 40,
    energyBoost: 15,
    preferredBy: [PetType.dragon, PetType.phoenix],
    rarity: PetRarity.epic,
    description: 'Traditional Japanese rice wine.',
    price: 45.0,
  ),
  const PetFood(
    name: 'Champagne',
    assetPath: 'assets/pets/food/drinks/champagne.png',
    category: FoodCategory.drinks,
    healthBoost: 10,
    happinessBoost: 60,
    energyBoost: 20,
    preferredBy: [PetType.unicorn, PetType.phoenix, PetType.dragon],
    rarity: PetRarity.legendary,
    description: 'Luxurious champagne for special celebrations.',
    price: 100.0,
  ),
  const PetFood(
    name: 'Margarita',
    assetPath: 'assets/pets/food/drinks/magarita.png',
    category: FoodCategory.drinks,
    healthBoost: 6,
    happinessBoost: 50,
    energyBoost: 25,
    preferredBy: [PetType.fox, PetType.wolf, PetType.phoenix],
    rarity: PetRarity.epic,
    description: 'Tropical margarita with a festive kick.',
    price: 35.0,
  ),
  const PetFood(
    name: 'Aperol',
    assetPath: 'assets/pets/food/drinks/aperol.png',
    category: FoodCategory.drinks,
    healthBoost: 7,
    happinessBoost: 38,
    energyBoost: 18,
    preferredBy: [PetType.fox, PetType.dragon],
    rarity: PetRarity.epic,
    description: 'Italian aperitif with a bitter-sweet taste.',
    price: 40.0,
  ),
  const PetFood(
    name: 'Gin',
    assetPath: 'assets/pets/food/drinks/gin.png',
    category: FoodCategory.drinks,
    healthBoost: 4,
    happinessBoost: 42,
    energyBoost: 12,
    preferredBy: [PetType.wolf, PetType.fox],
    rarity: PetRarity.epic,
    description: 'Premium gin with botanical flavors.',
    price: 38.0,
  ),

  // Fruits and Vegetables Category
  const PetFood(
    name: 'Carrot',
    assetPath: 'assets/pets/food/fruits_and_vegetables/carrot.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 15,
    happinessBoost: 30,
    energyBoost: 20,
    preferredBy: [PetType.bunny, PetType.unicorn],
    rarity: PetRarity.common,
    description: 'Sweet, crunchy carrot that bunnies adore.',
    price: 4.0,
  ),
  const PetFood(
    name: 'Apple',
    assetPath: 'assets/pets/food/fruits_and_vegetables/apple.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 12,
    happinessBoost: 18,
    energyBoost: 15,
    preferredBy: [PetType.bunny, PetType.unicorn],
    rarity: PetRarity.common,
    description: 'Fresh, crisp apple full of vitamins.',
    price: 5.0,
  ),
  const PetFood(
    name: 'Banana',
    assetPath: 'assets/pets/food/fruits_and_vegetables/banana.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 10,
    happinessBoost: 20,
    energyBoost: 25,
    preferredBy: [PetType.bunny, PetType.fox],
    rarity: PetRarity.common,
    description: 'Sweet banana packed with natural energy.',
    price: 3.0,
  ),
  const PetFood(
    name: 'Orange',
    assetPath: 'assets/pets/food/fruits_and_vegetables/orange.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 14,
    happinessBoost: 16,
    energyBoost: 18,
    preferredBy: [PetType.bunny, PetType.fox],
    rarity: PetRarity.common,
    description: 'Juicy orange rich in vitamin C.',
    price: 4.5,
  ),
  const PetFood(
    name: 'Strawberry',
    assetPath: 'assets/pets/food/fruits_and_vegetables/strawberry.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 8,
    happinessBoost: 25,
    energyBoost: 15,
    preferredBy: [PetType.bunny, PetType.fox, PetType.unicorn],
    rarity: PetRarity.uncommon,
    description: 'Sweet and juicy strawberry that pets love.',
    price: 6.0,
  ),
  const PetFood(
    name: 'Blueberry',
    assetPath: 'assets/pets/food/fruits_and_vegetables/blueberry.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 12,
    happinessBoost: 22,
    energyBoost: 18,
    preferredBy: [PetType.bunny, PetType.fox, PetType.wolf],
    rarity: PetRarity.uncommon,
    description: 'Antioxidant-rich blueberries for health.',
    price: 8.0,
  ),
  const PetFood(
    name: 'Pineapple',
    assetPath: 'assets/pets/food/fruits_and_vegetables/pineapple.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 16,
    happinessBoost: 28,
    energyBoost: 22,
    preferredBy: [PetType.bunny, PetType.fox, PetType.dragon],
    rarity: PetRarity.uncommon,
    description: 'Tropical pineapple with enzymes and vitamins.',
    price: 10.0,
  ),
  const PetFood(
    name: 'Watermelon',
    assetPath: 'assets/pets/food/fruits_and_vegetables/watermelon.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 18,
    happinessBoost: 30,
    energyBoost: 12,
    preferredBy: [PetType.bunny, PetType.axolotl, PetType.unicorn],
    rarity: PetRarity.uncommon,
    description: 'Refreshing watermelon perfect for hot days.',
    price: 12.0,
  ),
  const PetFood(
    name: 'Pear',
    assetPath: 'assets/pets/food/fruits_and_vegetables/pear.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 11,
    happinessBoost: 17,
    energyBoost: 14,
    preferredBy: [PetType.bunny, PetType.unicorn],
    rarity: PetRarity.common,
    description: 'Sweet and juicy pear with fiber.',
    price: 5.5,
  ),
  const PetFood(
    name: 'Lemon',
    assetPath: 'assets/pets/food/fruits_and_vegetables/lemon.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 6,
    happinessBoost: 10,
    energyBoost: 8,
    preferredBy: [PetType.fox],
    rarity: PetRarity.common,
    description: 'Tart lemon with high vitamin C content.',
    price: 3.5,
  ),
  const PetFood(
    name: 'Avocado',
    assetPath: 'assets/pets/food/fruits_and_vegetables/avocado.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 20,
    happinessBoost: 15,
    energyBoost: 25,
    preferredBy: [PetType.bunny, PetType.unicorn, PetType.dragon],
    rarity: PetRarity.rare,
    description: 'Nutrient-dense avocado with healthy fats.',
    price: 15.0,
  ),
  const PetFood(
    name: 'Potato',
    assetPath: 'assets/pets/food/fruits_and_vegetables/potatoe.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 18,
    happinessBoost: 12,
    energyBoost: 30,
    preferredBy: [PetType.bunny, PetType.dog],
    rarity: PetRarity.common,
    description: 'Hearty potato providing sustained energy.',
    price: 4.0,
  ),
  const PetFood(
    name: 'Corn',
    assetPath: 'assets/pets/food/fruits_and_vegetables/corn.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 15,
    happinessBoost: 20,
    energyBoost: 25,
    preferredBy: [PetType.bunny, PetType.dog],
    rarity: PetRarity.common,
    description: 'Sweet corn kernels full of energy.',
    price: 6.0,
  ),
  const PetFood(
    name: 'Peas',
    assetPath: 'assets/pets/food/fruits_and_vegetables/peas.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 12,
    happinessBoost: 14,
    energyBoost: 16,
    preferredBy: [PetType.bunny],
    rarity: PetRarity.common,
    description: 'Green peas packed with protein and vitamins.',
    price: 5.0,
  ),
  const PetFood(
    name: 'Broccoli',
    assetPath: 'assets/pets/food/fruits_and_vegetables/brocoli.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 22,
    happinessBoost: 8,
    energyBoost: 12,
    preferredBy: [PetType.bunny, PetType.unicorn],
    rarity: PetRarity.uncommon,
    description: 'Nutritious broccoli rich in vitamins and minerals.',
    price: 7.0,
  ),
  const PetFood(
    name: 'Butter Broccoli',
    assetPath: 'assets/pets/food/fruits_and_vegetables/butter_brocoli.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 25,
    happinessBoost: 18,
    energyBoost: 20,
    preferredBy: [PetType.bunny, PetType.unicorn, PetType.dragon],
    rarity: PetRarity.rare,
    description: 'Gourmet broccoli cooked in butter for extra flavor.',
    price: 12.0,
  ),
  const PetFood(
    name: 'Paprika',
    assetPath: 'assets/pets/food/fruits_and_vegetables/paprika.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 10,
    happinessBoost: 15,
    energyBoost: 18,
    preferredBy: [PetType.fox, PetType.wolf],
    rarity: PetRarity.uncommon,
    description: 'Sweet bell pepper with vibrant color.',
    price: 8.0,
  ),
  const PetFood(
    name: 'Eggplant',
    assetPath: 'assets/pets/food/fruits_and_vegetables/eggplant.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 14,
    happinessBoost: 12,
    energyBoost: 16,
    preferredBy: [PetType.bunny, PetType.dragon],
    rarity: PetRarity.uncommon,
    description: 'Purple eggplant with unique texture and taste.',
    price: 9.0,
  ),
  const PetFood(
    name: 'Mushroom',
    assetPath: 'assets/pets/food/fruits_and_vegetables/mushroom.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 16,
    happinessBoost: 20,
    energyBoost: 14,
    preferredBy: [PetType.bunny, PetType.fox, PetType.dragon],
    rarity: PetRarity.rare,
    description: 'Earthy mushroom with umami flavor.',
    price: 11.0,
  ),
  const PetFood(
    name: 'Chili',
    assetPath: 'assets/pets/food/fruits_and_vegetables/chili.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 8,
    happinessBoost: 25,
    energyBoost: 35,
    preferredBy: [PetType.fox, PetType.wolf, PetType.dragon],
    rarity: PetRarity.rare,
    description: 'Spicy chili that adds heat and energy.',
    price: 10.0,
  ),
  const PetFood(
    name: 'Onion',
    assetPath: 'assets/pets/food/fruits_and_vegetables/onion.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 6,
    happinessBoost: 8,
    energyBoost: 10,
    preferredBy: [PetType.wolf, PetType.fox],
    rarity: PetRarity.common,
    description: 'Pungent onion that adds flavor to meals.',
    price: 2.0,
  ),
  const PetFood(
    name: 'Garlic',
    assetPath: 'assets/pets/food/fruits_and_vegetables/garlic.png',
    category: FoodCategory.fruits_and_vegetables,
    healthBoost: 8,
    happinessBoost: 6,
    energyBoost: 12,
    preferredBy: [PetType.wolf, PetType.dragon],
    rarity: PetRarity.uncommon,
    description: 'Aromatic garlic with health benefits.',
    price: 4.0,
  ),

  // Meals Category
  const PetFood(
    name: 'Toast',
    assetPath: 'assets/pets/food/meals/toast.png',
    category: FoodCategory.meals,
    healthBoost: 8,
    happinessBoost: 15,
    energyBoost: 20,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny],
    rarity: PetRarity.common,
    description: 'Simple toasted bread perfect for breakfast.',
    price: 3.0,
  ),
  const PetFood(
    name: 'Eggs',
    assetPath: 'assets/pets/food/meals/eggs.png',
    category: FoodCategory.meals,
    healthBoost: 18,
    happinessBoost: 12,
    energyBoost: 25,
    preferredBy: [PetType.cat, PetType.dog, PetType.fox, PetType.wolf],
    rarity: PetRarity.common,
    description: 'Protein-rich eggs for a nutritious meal.',
    price: 5.0,
  ),
  const PetFood(
    name: 'Eggs and Bacon',
    assetPath: 'assets/pets/food/meals/eggs_and_baacon.png',
    category: FoodCategory.meals,
    healthBoost: 25,
    happinessBoost: 30,
    energyBoost: 35,
    preferredBy: [PetType.cat, PetType.dog, PetType.fox, PetType.wolf],
    rarity: PetRarity.uncommon,
    description: 'Classic breakfast combination of eggs and crispy bacon.',
    price: 12.0,
  ),
  const PetFood(
    name: 'Pancakes',
    assetPath: 'assets/pets/food/meals/pancakes.png',
    category: FoodCategory.meals,
    healthBoost: 15,
    happinessBoost: 35,
    energyBoost: 30,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny, PetType.fox],
    rarity: PetRarity.uncommon,
    description: 'Fluffy pancakes that bring morning joy.',
    price: 10.0,
  ),
  const PetFood(
    name: 'Rice Bowl',
    assetPath: 'assets/pets/food/meals/rice_bowl.png',
    category: FoodCategory.meals,
    healthBoost: 20,
    happinessBoost: 18,
    energyBoost: 28,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny, PetType.axolotl],
    rarity: PetRarity.common,
    description: 'Simple bowl of steamed rice for sustained energy.',
    price: 6.0,
  ),
  const PetFood(
    name: 'Salad',
    assetPath: 'assets/pets/food/meals/salad.png',
    category: FoodCategory.meals,
    healthBoost: 25,
    happinessBoost: 15,
    energyBoost: 12,
    preferredBy: [PetType.bunny, PetType.unicorn],
    rarity: PetRarity.common,
    description: 'Fresh mixed salad packed with vitamins.',
    price: 8.0,
  ),
  const PetFood(
    name: 'Salad Bowl',
    assetPath: 'assets/pets/food/meals/salad_bowl.png',
    category: FoodCategory.meals,
    healthBoost: 30,
    happinessBoost: 20,
    energyBoost: 15,
    preferredBy: [PetType.bunny, PetType.unicorn],
    rarity: PetRarity.uncommon,
    description: 'Large salad bowl with premium greens.',
    price: 15.0,
  ),
  const PetFood(
    name: 'Cheese',
    assetPath: 'assets/pets/food/meals/cheese.png',
    category: FoodCategory.meals,
    healthBoost: 12,
    happinessBoost: 25,
    energyBoost: 18,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny],
    rarity: PetRarity.common,
    description: 'Rich cheese that pets find irresistible.',
    price: 7.0,
  ),
  const PetFood(
    name: 'Spaghetti',
    assetPath: 'assets/pets/food/meals/sphagetti.png',
    category: FoodCategory.meals,
    healthBoost: 22,
    happinessBoost: 28,
    energyBoost: 35,
    preferredBy: [PetType.cat, PetType.dog, PetType.fox],
    rarity: PetRarity.uncommon,
    description: 'Delicious pasta dish with rich sauce.',
    price: 14.0,
  ),
  const PetFood(
    name: 'Pizza',
    assetPath: 'assets/pets/food/meals/pizza.png',
    category: FoodCategory.meals,
    healthBoost: 20,
    happinessBoost: 40,
    energyBoost: 30,
    preferredBy: [PetType.cat, PetType.dog, PetType.fox, PetType.wolf],
    rarity: PetRarity.rare,
    description: 'Cheesy pizza slice that everyone loves.',
    price: 18.0,
  ),
  const PetFood(
    name: 'Burger',
    assetPath: 'assets/pets/food/meals/burger.png',
    category: FoodCategory.meals,
    healthBoost: 25,
    happinessBoost: 35,
    energyBoost: 40,
    preferredBy: [PetType.dog, PetType.fox, PetType.wolf],
    rarity: PetRarity.rare,
    description: 'Juicy burger with all the fixings.',
    price: 20.0,
  ),
  const PetFood(
    name: 'Taco',
    assetPath: 'assets/pets/food/meals/taco.png',
    category: FoodCategory.meals,
    healthBoost: 18,
    happinessBoost: 32,
    energyBoost: 28,
    preferredBy: [PetType.dog, PetType.fox, PetType.wolf],
    rarity: PetRarity.uncommon,
    description: 'Spicy taco filled with meat and vegetables.',
    price: 16.0,
  ),
  const PetFood(
    name: 'Sushi',
    assetPath: 'assets/pets/food/meals/sushi.png',
    category: FoodCategory.meals,
    healthBoost: 30,
    happinessBoost: 25,
    energyBoost: 20,
    preferredBy: [PetType.cat, PetType.axolotl, PetType.dragon],
    rarity: PetRarity.rare,
    description: 'Artfully prepared sushi with fresh fish.',
    price: 25.0,
  ),
  const PetFood(
    name: 'Sashimi',
    assetPath: 'assets/pets/food/meals/sashimi.png',
    category: FoodCategory.meals,
    healthBoost: 35,
    happinessBoost: 30,
    energyBoost: 25,
    preferredBy: [PetType.cat, PetType.axolotl, PetType.dragon],
    rarity: PetRarity.rare,
    description: 'Premium raw fish slices of the highest quality.',
    price: 30.0,
  ),
  const PetFood(
    name: 'Onigiri',
    assetPath: 'assets/pets/food/meals/onigiri.png',
    category: FoodCategory.meals,
    healthBoost: 16,
    happinessBoost: 22,
    energyBoost: 24,
    preferredBy: [PetType.cat, PetType.bunny, PetType.fox],
    rarity: PetRarity.uncommon,
    description: 'Traditional rice ball with savory filling.',
    price: 9.0,
  ),
  const PetFood(
    name: 'Beef Steak',
    assetPath: 'assets/pets/food/meals/beef_steak.png',
    category: FoodCategory.meals,
    healthBoost: 40,
    happinessBoost: 35,
    energyBoost: 45,
    preferredBy: [PetType.dog, PetType.wolf, PetType.fox, PetType.dragon],
    rarity: PetRarity.epic,
    description: 'Premium grilled steak cooked to perfection.',
    price: 50.0,
  ),
  const PetFood(
    name: 'Potato Schnitzel',
    assetPath: 'assets/pets/food/meals/potatoe_schnitzel.png',
    category: FoodCategory.meals,
    healthBoost: 32,
    happinessBoost: 28,
    energyBoost: 38,
    preferredBy: [PetType.dog, PetType.wolf, PetType.fox],
    rarity: PetRarity.rare,
    description: 'Crispy breaded schnitzel with potato sides.',
    price: 35.0,
  ),
  const PetFood(
    name: 'Cordon Bleu',
    assetPath: 'assets/pets/food/meals/codom_bleu.png',
    category: FoodCategory.meals,
    healthBoost: 45,
    happinessBoost: 40,
    energyBoost: 50,
    preferredBy: [PetType.cat, PetType.dog, PetType.dragon, PetType.phoenix],
    rarity: PetRarity.legendary,
    description: 'Gourmet stuffed chicken dish with ham and cheese.',
    price: 100.0,
  ),

  // Meat Category
  const PetFood(
    name: 'Sausage',
    assetPath: 'assets/pets/food/meat/sausage.png',
    category: FoodCategory.meat,
    healthBoost: 20,
    happinessBoost: 25,
    energyBoost: 30,
    preferredBy: [PetType.dog, PetType.wolf, PetType.fox],
    rarity: PetRarity.common,
    description: 'Juicy sausage packed with flavor and protein.',
    price: 8.0,
  ),
  const PetFood(
    name: 'Big Sausage',
    assetPath: 'assets/pets/food/meat/big_sausage.png',
    category: FoodCategory.meat,
    healthBoost: 30,
    happinessBoost: 35,
    energyBoost: 40,
    preferredBy: [PetType.dog, PetType.wolf, PetType.fox],
    rarity: PetRarity.uncommon,
    description: 'Large, hearty sausage for bigger appetites.',
    price: 15.0,
  ),
  const PetFood(
    name: 'Meatball',
    assetPath: 'assets/pets/food/meat/meatball.png',
    category: FoodCategory.meat,
    healthBoost: 18,
    happinessBoost: 22,
    energyBoost: 25,
    preferredBy: [PetType.cat, PetType.dog, PetType.fox],
    rarity: PetRarity.common,
    description: 'Perfectly seasoned meatball with rich taste.',
    price: 6.0,
  ),
  const PetFood(
    name: 'Bacon',
    assetPath: 'assets/pets/food/meat/bacon.png',
    category: FoodCategory.meat,
    healthBoost: 15,
    happinessBoost: 35,
    energyBoost: 28,
    preferredBy: [PetType.cat, PetType.dog, PetType.fox, PetType.wolf],
    rarity: PetRarity.uncommon,
    description: 'Crispy bacon strips that pets absolutely love.',
    price: 12.0,
  ),
  const PetFood(
    name: 'Chicken Wing',
    assetPath: 'assets/pets/food/meat/chicken_wing.png',
    category: FoodCategory.meat,
    healthBoost: 22,
    happinessBoost: 28,
    energyBoost: 32,
    preferredBy: [PetType.cat, PetType.dog, PetType.fox, PetType.griffin],
    rarity: PetRarity.uncommon,
    description: 'Tender chicken wing with crispy skin.',
    price: 10.0,
  ),
  const PetFood(
    name: 'Shrimp',
    assetPath: 'assets/pets/food/meat/shrimp.png',
    category: FoodCategory.meat,
    healthBoost: 25,
    happinessBoost: 30,
    energyBoost: 20,
    preferredBy: [PetType.cat, PetType.axolotl, PetType.dragon],
    rarity: PetRarity.rare,
    description: 'Fresh shrimp rich in protein and delicate flavor.',
    price: 18.0,
  ),
  const PetFood(
    name: 'Steak',
    assetPath: 'assets/pets/food/meat/steak.png',
    category: FoodCategory.meat,
    healthBoost: 40,
    happinessBoost: 40,
    energyBoost: 45,
    preferredBy: [PetType.dog, PetType.wolf, PetType.fox, PetType.dragon],
    rarity: PetRarity.rare,
    description: 'Premium steak grilled to perfection.',
    price: 35.0,
  ),
  const PetFood(
    name: 'Rib',
    assetPath: 'assets/pets/food/meat/rib.png',
    category: FoodCategory.meat,
    healthBoost: 35,
    happinessBoost: 45,
    energyBoost: 40,
    preferredBy: [PetType.dog, PetType.wolf, PetType.dragon],
    rarity: PetRarity.epic,
    description: 'Succulent rib with tender meat falling off the bone.',
    price: 50.0,
  ),
  const PetFood(
    name: 'Lionar',
    assetPath: 'assets/pets/food/meat/Lionar.png',
    category: FoodCategory.meat,
    healthBoost: 60,
    happinessBoost: 55,
    energyBoost: 65,
    preferredBy: [PetType.dragon, PetType.phoenix, PetType.griffin, PetType.wolf],
    rarity: PetRarity.legendary,
    description: 'Exotic Lionar meat from legendary beasts.',
    price: 200.0,
  ),

  // Sweets Category
  const PetFood(
    name: 'Cookie',
    assetPath: 'assets/pets/food/sweets/cookie.png',
    category: FoodCategory.sweets,
    healthBoost: 5,
    happinessBoost: 30,
    energyBoost: 20,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny],
    rarity: PetRarity.common,
    description: 'Classic cookie that brings simple joy.',
    price: 6.0,
  ),
  const PetFood(
    name: 'Chocolate Cookie',
    assetPath: 'assets/pets/food/sweets/choco_cookie.png',
    category: FoodCategory.sweets,
    healthBoost: 8,
    happinessBoost: 35,
    energyBoost: 25,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny, PetType.fox],
    rarity: PetRarity.uncommon,
    description: 'Rich chocolate cookie for extra sweetness.',
    price: 10.0,
  ),
  const PetFood(
    name: 'Candy',
    assetPath: 'assets/pets/food/sweets/candy.png',
    category: FoodCategory.sweets,
    healthBoost: 3,
    happinessBoost: 40,
    energyBoost: 35,
    preferredBy: [PetType.bunny, PetType.fox, PetType.unicorn],
    rarity: PetRarity.common,
    description: 'Colorful candy that brings instant happiness.',
    price: 4.0,
  ),
  const PetFood(
    name: 'Lollipop',
    assetPath: 'assets/pets/food/sweets/lollipop.png',
    category: FoodCategory.sweets,
    healthBoost: 5,
    happinessBoost: 45,
    energyBoost: 30,
    preferredBy: [PetType.bunny, PetType.fox, PetType.unicorn],
    rarity: PetRarity.uncommon,
    description: 'Sweet lollipop that lasts a long time.',
    price: 8.0,
  ),
  const PetFood(
    name: 'Honey',
    assetPath: 'assets/pets/food/sweets/honey.png',
    category: FoodCategory.sweets,
    healthBoost: 12,
    happinessBoost: 35,
    energyBoost: 40,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny, PetType.fox],
    rarity: PetRarity.uncommon,
    description: 'Pure honey with natural sweetness and energy.',
    price: 12.0,
  ),
  const PetFood(
    name: 'Chocolate',
    assetPath: 'assets/pets/food/sweets/chocolate.png',
    category: FoodCategory.sweets,
    healthBoost: 8,
    happinessBoost: 50,
    energyBoost: 35,
    preferredBy: [PetType.cat, PetType.dog, PetType.fox, PetType.unicorn],
    rarity: PetRarity.rare,
    description: 'Rich dark chocolate that pets adore.',
    price: 15.0,
  ),
  const PetFood(
    name: 'Muffin',
    assetPath: 'assets/pets/food/sweets/muffin.png',
    category: FoodCategory.sweets,
    healthBoost: 10,
    happinessBoost: 25,
    energyBoost: 30,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny],
    rarity: PetRarity.common,
    description: 'Fluffy muffin perfect for breakfast treats.',
    price: 9.0,
  ),
  const PetFood(
    name: 'Chocolate Muffin',
    assetPath: 'assets/pets/food/sweets/choco_muffin.png',
    category: FoodCategory.sweets,
    healthBoost: 12,
    happinessBoost: 35,
    energyBoost: 32,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny, PetType.fox],
    rarity: PetRarity.uncommon,
    description: 'Decadent chocolate muffin with rich flavor.',
    price: 14.0,
  ),
  const PetFood(
    name: 'Pink Muffin',
    assetPath: 'assets/pets/food/sweets/pink_muffin.png',
    category: FoodCategory.sweets,
    healthBoost: 10,
    happinessBoost: 40,
    energyBoost: 28,
    preferredBy: [PetType.bunny, PetType.unicorn, PetType.fox],
    rarity: PetRarity.uncommon,
    description: 'Pretty pink muffin with berry flavoring.',
    price: 12.0,
  ),
  const PetFood(
    name: 'Vanilla Muffin',
    assetPath: 'assets/pets/food/sweets/vanilla_muffin.png',
    category: FoodCategory.sweets,
    healthBoost: 11,
    happinessBoost: 30,
    energyBoost: 29,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny],
    rarity: PetRarity.common,
    description: 'Classic vanilla muffin with subtle sweetness.',
    price: 10.0,
  ),
  const PetFood(
    name: 'Donut',
    assetPath: 'assets/pets/food/sweets/donut.png',
    category: FoodCategory.sweets,
    healthBoost: 8,
    happinessBoost: 45,
    energyBoost: 35,
    preferredBy: [PetType.cat, PetType.dog, PetType.fox],
    rarity: PetRarity.uncommon,
    description: 'Glazed donut with irresistible sweetness.',
    price: 11.0,
  ),
  const PetFood(
    name: 'Cinnamon Roll',
    assetPath: 'assets/pets/food/sweets/cinnamon_roll.png',
    category: FoodCategory.sweets,
    healthBoost: 15,
    happinessBoost: 40,
    energyBoost: 38,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny, PetType.fox],
    rarity: PetRarity.rare,
    description: 'Warm cinnamon roll with sweet glaze.',
    price: 18.0,
  ),
  const PetFood(
    name: 'Sweet Croissant',
    assetPath: 'assets/pets/food/sweets/sweet_croissant.png',
    category: FoodCategory.sweets,
    healthBoost: 14,
    happinessBoost: 35,
    energyBoost: 40,
    preferredBy: [PetType.cat, PetType.dog, PetType.fox, PetType.unicorn],
    rarity: PetRarity.rare,
    description: 'Buttery croissant with sweet filling.',
    price: 16.0,
  ),
  const PetFood(
    name: 'Vanilla Ice Cream',
    assetPath: 'assets/pets/food/sweets/vanilla_ice_cream.png',
    category: FoodCategory.sweets,
    healthBoost: 6,
    happinessBoost: 50,
    energyBoost: 25,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny, PetType.fox],
    rarity: PetRarity.uncommon,
    description: 'Creamy vanilla ice cream that cools and delights.',
    price: 13.0,
  ),
  const PetFood(
    name: 'Baby Ice Cream',
    assetPath: 'assets/pets/food/sweets/baby_ice_cream.png',
    category: FoodCategory.sweets,
    healthBoost: 5,
    happinessBoost: 55,
    energyBoost: 20,
    preferredBy: [PetType.bunny, PetType.unicorn],
    rarity: PetRarity.rare,
    description: 'Adorable mini ice cream perfect for small treats.',
    price: 15.0,
  ),
  const PetFood(
    name: 'Cotton Ice Cream',
    assetPath: 'assets/pets/food/sweets/cotton_ice_cream.png',
    category: FoodCategory.sweets,
    healthBoost: 8,
    happinessBoost: 60,
    energyBoost: 30,
    preferredBy: [PetType.bunny, PetType.fox, PetType.unicorn],
    rarity: PetRarity.rare,
    description: 'Fluffy cotton candy flavored ice cream.',
    price: 20.0,
  ),
  const PetFood(
    name: 'Cotton Candy',
    assetPath: 'assets/pets/food/sweets/cotton_candy.png',
    category: FoodCategory.sweets,
    healthBoost: 3,
    happinessBoost: 65,
    energyBoost: 45,
    preferredBy: [PetType.bunny, PetType.fox, PetType.unicorn],
    rarity: PetRarity.rare,
    description: 'Fluffy cotton candy that melts in your mouth.',
    price: 22.0,
  ),
  const PetFood(
    name: 'Cotton Berry',
    assetPath: 'assets/pets/food/sweets/cotton_berry.png',
    category: FoodCategory.sweets,
    healthBoost: 5,
    happinessBoost: 60,
    energyBoost: 40,
    preferredBy: [PetType.bunny, PetType.fox, PetType.unicorn],
    rarity: PetRarity.rare,
    description: 'Berry-flavored cotton candy with natural fruit taste.',
    price: 24.0,
  ),
  const PetFood(
    name: 'Cake',
    assetPath: 'assets/pets/food/sweets/cake.png',
    category: FoodCategory.sweets,
    healthBoost: 20,
    happinessBoost: 55,
    energyBoost: 45,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny, PetType.fox, PetType.unicorn],
    rarity: PetRarity.epic,
    description: 'Beautiful celebration cake for special occasions.',
    price: 35.0,
  ),
  const PetFood(
    name: 'Chocolate Cake',
    assetPath: 'assets/pets/food/sweets/choco_cake.png',
    category: FoodCategory.sweets,
    healthBoost: 25,
    happinessBoost: 70,
    energyBoost: 50,
    preferredBy: [PetType.cat, PetType.dog, PetType.fox, PetType.unicorn, PetType.dragon],
    rarity: PetRarity.epic,
    description: 'Rich chocolate cake that brings ultimate joy.',
    price: 45.0,
  ),
  const PetFood(
    name: 'Strawberry Cake',
    assetPath: 'assets/pets/food/sweets/strawberry_cake.png',
    category: FoodCategory.sweets,
    healthBoost: 22,
    happinessBoost: 65,
    energyBoost: 48,
    preferredBy: [PetType.bunny, PetType.fox, PetType.unicorn, PetType.phoenix],
    rarity: PetRarity.epic,
    description: 'Elegant strawberry cake with fresh berry flavor.',
    price: 40.0,
  ),
  const PetFood(
    name: 'Pie',
    assetPath: 'assets/pets/food/sweets/pie.png',
    category: FoodCategory.sweets,
    healthBoost: 18,
    happinessBoost: 50,
    energyBoost: 42,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny, PetType.fox],
    rarity: PetRarity.rare,
    description: 'Traditional pie with flaky crust and sweet filling.',
    price: 28.0,
  ),
  const PetFood(
    name: 'Mixed Pie',
    assetPath: 'assets/pets/food/sweets/mixed_pie.png',
    category: FoodCategory.sweets,
    healthBoost: 20,
    happinessBoost: 55,
    energyBoost: 45,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny, PetType.fox, PetType.unicorn],
    rarity: PetRarity.epic,
    description: 'Special mixed pie with multiple delicious flavors.',
    price: 32.0,
  ),
  const PetFood(
    name: 'Chocolate Heart',
    assetPath: 'assets/pets/food/sweets/choco_heart.png',
    category: FoodCategory.sweets,
    healthBoost: 15,
    happinessBoost: 80,
    energyBoost: 35,
    preferredBy: [PetType.cat, PetType.dog, PetType.bunny, PetType.fox, PetType.unicorn],
    rarity: PetRarity.legendary,
    description: 'Heart-shaped chocolate that expresses love and care.',
    price: 75.0,
  ),
  const PetFood(
    name: 'Chocolate Poop',
    assetPath: 'assets/pets/food/sweets/choco_poop.png',
    category: FoodCategory.sweets,
    healthBoost: 10,
    happinessBoost: 90,
    energyBoost: 40,
    preferredBy: [PetType.cat, PetType.dog, PetType.fox, PetType.wolf],
    rarity: PetRarity.legendary,
    description: 'Hilariously shaped chocolate treat that pets find amusing.',
    price: 100.0,
  ),
];

// Utility functions for pet management
class PetUtils {
  static List<Pet> getPetsByRarity(PetRarity rarity) {
    return availablePets.where((pet) => pet.rarity == rarity).toList();
  }

  static List<Pet> getPetsByType(PetType type) {
    return availablePets.where((pet) => pet.type == type).toList();
  }

  static Pet? getPetById(String id) {
    try {
      return availablePets.firstWhere((pet) => pet.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Pet> getOwnedPets(List<String> ownedPetIds) {
    return availablePets.where((pet) => ownedPetIds.contains(pet.id)).toList();
  }

  static List<Pet> getAvailableForPurchase(List<String> ownedPetIds) {
    return availablePets.where((pet) => !ownedPetIds.contains(pet.id)).toList();
  }

  static List<Pet> getPetsByShopCategory(String category) {
    return availablePets.where((pet) => pet.shopCategory == category).toList();
  }

  static List<Pet> searchPets(String query) {
    final lowercaseQuery = query.toLowerCase();
    return availablePets.where((pet) {
      return pet.name.toLowerCase().contains(lowercaseQuery) ||
             pet.description.toLowerCase().contains(lowercaseQuery) ||
             pet.type.name.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  static Color getRarityColor(PetRarity rarity) {
    switch (rarity) {
      case PetRarity.common:
        return Colors.grey;
      case PetRarity.uncommon:
        return Colors.green;
      case PetRarity.rare:
        return Colors.blue;
      case PetRarity.epic:
        return Colors.purple;
      case PetRarity.legendary:
        return Colors.orange;
      case PetRarity.mythical:
        return Colors.pink;
    }
  }

  // Food utility functions
  static List<PetFood> getFoodsByCategory(FoodCategory category) {
    return availableFoods.where((food) => food.category == category).toList();
  }

  static List<PetFood> getFoodsByRarity(PetRarity rarity) {
    return availableFoods.where((food) => food.rarity == rarity).toList();
  }

  static List<PetFood> getFoodsForPetType(PetType petType) {
    return availableFoods.where((food) => food.preferredBy.contains(petType)).toList();
  }

  static PetFood? getFoodByName(String name) {
    try {
      return availableFoods.firstWhere((food) => food.name == name);
    } catch (e) {
      return null;
    }
  }

  static List<PetFood> searchFoods(String query) {
    final lowercaseQuery = query.toLowerCase();
    return availableFoods.where((food) {
      return food.name.toLowerCase().contains(lowercaseQuery) ||
             food.description.toLowerCase().contains(lowercaseQuery) ||
             food.category.name.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  static List<PetFood> getFoodsSortedByPrice({bool ascending = true}) {
    final sortedFoods = List<PetFood>.from(availableFoods);
    sortedFoods.sort((a, b) => ascending ? a.price.compareTo(b.price) : b.price.compareTo(a.price));
    return sortedFoods;
  }

  static List<PetFood> getFoodsInPriceRange(double minPrice, double maxPrice) {
    return availableFoods.where((food) => food.price >= minPrice && food.price <= maxPrice).toList();
  }

  static Map<FoodCategory, List<PetFood>> getFoodsGroupedByCategory() {
    final Map<FoodCategory, List<PetFood>> groupedFoods = {};
    for (FoodCategory category in FoodCategory.values) {
      groupedFoods[category] = getFoodsByCategory(category);
    }
    return groupedFoods;
  }

  static double calculateFeedingCost(List<PetFood> foods) {
    return foods.fold(0.0, (sum, food) => sum + food.price);
  }

  static List<PetFood> getRecommendedFoodsForPet(Pet pet, {int maxItems = 5}) {
    // Get foods preferred by this pet type
    var preferredFoods = getFoodsForPetType(pet.type);
    
    // Sort by effectiveness (total stat boost) and rarity
    preferredFoods.sort((a, b) {
      final aEffectiveness = a.healthBoost + a.happinessBoost + a.energyBoost;
      final bEffectiveness = b.healthBoost + b.happinessBoost + b.energyBoost;
      
      if (aEffectiveness != bEffectiveness) {
        return bEffectiveness.compareTo(aEffectiveness);
      }
      return b.rarity.index.compareTo(a.rarity.index);
    });
    
    return preferredFoods.take(maxItems).toList();
  }
}
