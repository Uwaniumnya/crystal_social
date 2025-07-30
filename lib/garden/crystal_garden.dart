import 'package:flutter/material.dart';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'garden_production_config.dart';

enum FlowerRarity { common, rare, epic }

enum FlowerGrowthStage { seed, sprout, bud, bloomed }

enum WeatherType { sunny, rainy, snowy, windy, misty }

enum SeasonType { spring, summer, autumn, winter }

enum GardenTheme { classic, enchanted, tropical, desert, arctic }

class FlowerSpecies {
  final String name;
  final String description;
  final List<Color> colors;
  final FlowerRarity rarity;
  final List<String> bloomSounds;
  
  FlowerSpecies({
    required this.name,
    required this.description,
    required this.colors,
    required this.rarity,
    required this.bloomSounds,
  });
}

class Flower {
  final String id;
  final String imagePath;
  final FlowerRarity rarity;
  final double xPosition;
  final double yPosition;
  FlowerGrowthStage growthStage;
  DateTime? lastWatered;
  DateTime? lastFertilized;
  bool hasBloomedAndSung;
  int health;
  int happiness;
  String species;
  double age; // in hours
  bool isPest;
  bool hasSpecialEffect;
  
  Flower({
    required this.id,
    required this.imagePath,
    required this.rarity,
    required this.xPosition,
    required this.yPosition,
    this.growthStage = FlowerGrowthStage.seed,
    this.lastWatered,
    this.lastFertilized,
    this.hasBloomedAndSung = false,
    this.health = 100,
    this.happiness = 50,
    this.species = "Rose",
    this.age = 0,
    this.isPest = false,
    this.hasSpecialEffect = false,
  });

  bool get canGrow {
    if (lastWatered == null) return false;
    if (health < 30) return false;
    return DateTime.now().difference(lastWatered!) > Duration(hours: 1);
  }

  bool get needsWater {
    if (lastWatered == null) return true;
    return DateTime.now().difference(lastWatered!) > Duration(hours: 2);
  }

  bool get needsFertilizer {
    if (lastFertilized == null) return true;
    return DateTime.now().difference(lastFertilized!) > Duration(hours: 6);
  }

  bool get isWilting {
    return health < 50 || needsWater;
  }

  String get currentImagePath {
    String basePath = 'assets/garden/flowers/';
    String rarityFolder = rarity.name;
    return '$basePath$rarityFolder/${imagePath.split('/').last}';
  }

  double get currentSize {
    double baseSize = switch (growthStage) {
      FlowerGrowthStage.seed => 0.3,
      FlowerGrowthStage.sprout => 0.5,
      FlowerGrowthStage.bud => 0.7,
      FlowerGrowthStage.bloomed => 1.0,
    };
    
    // Health affects size
    double healthMultiplier = health / 100.0;
    return baseSize * (0.7 + 0.3 * healthMultiplier);
  }

  Color get healthColor {
    if (health >= 80) return Colors.green;
    if (health >= 50) return Colors.yellow;
    if (health >= 20) return Colors.orange;
    return Colors.red;
  }

  void water() {
    lastWatered = DateTime.now();
    health = (health + 10).clamp(0, 100);
    happiness = (happiness + 5).clamp(0, 100);
  }

  void fertilize() {
    lastFertilized = DateTime.now();
    health = (health + 20).clamp(0, 100);
    happiness = (happiness + 15).clamp(0, 100);
  }

  void updateAge() {
    age += 0.1; // Increase age
    if (age > 24 && Random().nextDouble() < 0.1) {
      health = max(0, health - 1); // Gradual aging
    }
  }

  bool tryToGrow() {
    if (!canGrow || growthStage == FlowerGrowthStage.bloomed) return false;
    
    // Higher rarity flowers have lower growth chance but better rewards
    double growthChance = switch (rarity) {
      FlowerRarity.common => 0.8,
      FlowerRarity.rare => 0.4,
      FlowerRarity.epic => 0.3,
    };
    
    if (Random().nextDouble() > growthChance) return false;
    
    switch (growthStage) {
      case FlowerGrowthStage.seed:
        growthStage = FlowerGrowthStage.sprout;
        break;
      case FlowerGrowthStage.sprout:
        growthStage = FlowerGrowthStage.bud;
        break;
      case FlowerGrowthStage.bud:
        growthStage = FlowerGrowthStage.bloomed;
        if (rarity == FlowerRarity.epic) {
          hasSpecialEffect = true;
        }
        return true; // Bloomed!
      case FlowerGrowthStage.bloomed:
        return false;
    }
    return false;
  }
}

class GardenVisitor {
  final String name;
  final String imagePath;
  final String reward;
  final Duration stayDuration;
  DateTime? arrivalTime;
  
  GardenVisitor({
    required this.name,
    required this.imagePath,
    required this.reward,
    required this.stayDuration,
    this.arrivalTime,
  });
  
  bool get isActive => arrivalTime != null && 
    DateTime.now().difference(arrivalTime!) < stayDuration;
}

class CrystalGarden {
  CrystalGarden({
    required this.backgroundImage,
    this.theme = GardenTheme.classic,
    this.season = SeasonType.spring,
  });

  final String backgroundImage;
  final GardenTheme theme;
  final SeasonType season;
  int coins = 0;
  int gems = 0;
  int level = 1;
  int experience = 0;
  List<Flower> flowers = [];
  List<GardenVisitor> visitors = [];
  DateTime? lastPestCheck;
  bool hasDecoration = false;
  String decorationType = '';
  double fertility = 100.0;
  Map<String, int> inventory = {
    'water': 10,
    'fertilizer': 5,
    'pesticide': 3,
    'seeds_common': 5,
    'seeds_rare': 1,
  };

  void addFlower(Flower flower) {
    if (flowers.length < getMaxFlowers()) {
      flowers.add(flower);
    }
  }

  int getMaxFlowers() {
    return 6 + (level * 2); // More flowers as level increases
  }

  List<Flower> getFlowersNeedingWater() {
    return flowers.where((flower) => flower.needsWater).toList();
  }

  List<Flower> getFlowersNeedingFertilizer() {
    return flowers.where((flower) => flower.needsFertilizer).toList();
  }

  void addExperience(int exp) {
    experience += exp;
    checkLevelUp();
  }

  void checkLevelUp() {
    int requiredExp = level * 100;
    if (experience >= requiredExp) {
      level++;
      experience -= requiredExp;
      // Level up rewards
      coins += level * 50;
      gems += level;
    }
  }

  bool useItem(String item, int amount) {
    if (inventory[item] != null && inventory[item]! >= amount) {
      inventory[item] = inventory[item]! - amount;
      return true;
    }
    return false;
  }

  void addToInventory(String item, int amount) {
    inventory[item] = (inventory[item] ?? 0) + amount;
  }
}

class EnhancedCrystalGardenScreen extends StatefulWidget {
  const EnhancedCrystalGardenScreen({super.key});

  @override
  _EnhancedCrystalGardenScreenState createState() => _EnhancedCrystalGardenScreenState();
}

class _EnhancedCrystalGardenScreenState extends State<EnhancedCrystalGardenScreen>
    with TickerProviderStateMixin {
  int currentPageIndex = 0;
  final List<String> gardenBackgrounds = [
    'assets/garden/backgrounds/garden_1.png',
    'assets/garden/backgrounds/garden_2.png',
    'assets/garden/backgrounds/garden_3.png',
    'assets/garden/backgrounds/garden_4.png',
    'assets/garden/backgrounds/garden_5.png',
    'assets/garden/backgrounds/garden_6.png',
    'assets/garden/backgrounds/garden_7.png',
    'assets/garden/backgrounds/garden_8.png',
    'assets/garden/backgrounds/garden_9.png',
    'assets/garden/backgrounds/garden_10.png',
    'assets/garden/backgrounds/garden_11.png',
    'assets/garden/backgrounds/garden_12.png',
    'assets/garden/backgrounds/garden_13.png',
    'assets/garden/backgrounds/garden_14.png',
    'assets/garden/backgrounds/garden_15.png',
    'assets/garden/backgrounds/garden_16.png',
    'assets/garden/backgrounds/garden_17.png',
    'assets/garden/backgrounds/garden_18.png',
    'assets/garden/backgrounds/garden_19.png',
    'assets/garden/backgrounds/garden_20.png',
    'assets/garden/backgrounds/garden_21.png',
  ];

  List<CrystalGarden> userGardens = [];
  String userId = '';

  late AudioPlayer _bgMusicPlayer;
  late AudioPlayer _songPlayer;
  late AudioPlayer _effectPlayer;
  late ConfettiController _confettiController;
  late AnimationController _weatherController;
  late Animation<double> _weatherAnimation;

  DateTime? _lastWaterTime;
  DateTime? _lastFertilizerTime;
  bool _watering = false;
  bool _fertilizing = false;
  int? _wateringFlowerIndex;
  String _selectedTool = 'water'; // water, fertilizer, pesticide, seeds

  // Enhanced visitor system
  late Timer _beeTimer;
  late Timer _snailTimer;
  late Timer _visitorTimer;
  late Timer _growthCheckTimer;
  late Timer _weatherTimer;
  late Timer _pestTimer;
  
  bool showBee = false;
  bool showSnail = false;
  double beeX = 0.0;
  double beeY = 0.0;
  double snailX = 0.0;
  
  WeatherType weatherType = WeatherType.sunny;
  SeasonType currentSeason = SeasonType.spring;
  bool _showStats = false;
  bool _showShop = false;

  bool get canWater => _lastWaterTime == null || 
    DateTime.now().difference(_lastWaterTime!) > Duration(minutes: 30);
  
  bool get canFertilize => _lastFertilizerTime == null || 
    DateTime.now().difference(_lastFertilizerTime!) > Duration(hours: 1);

  @override
  void dispose() {
    _beeTimer.cancel();
    _snailTimer.cancel();
    _visitorTimer.cancel();
    _growthCheckTimer.cancel();
    _weatherTimer.cancel();
    _pestTimer.cancel();
    _confettiController.dispose();
    _weatherController.dispose();
    _bgMusicPlayer.dispose();
    _songPlayer.dispose();
    _effectPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAudio();
    _initializeGame();
    _startTimers();
  }

  void _initializeControllers() {
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));

    _weatherController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _weatherAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _weatherController, curve: Curves.easeInOut),
    );
    _weatherController.repeat();
  }

  void _initializeAudio() {
    _bgMusicPlayer = AudioPlayer();
    _songPlayer = AudioPlayer();
    _effectPlayer = AudioPlayer();
    _playBackgroundMusic();
  }

  void _initializeGame() {
    _loadCoinBalance();
    _setWeatherType();
    _setSeason();
    _createNewGarden();
  }

  void _startTimers() {
    _startBeeVisitor();
    _startSnailVisitor();
    _startRandomVisitor();
    _startGrowthChecker();
    _startWeatherChanger();
    _startPestChecker();
  }

  Future<void> _playBackgroundMusic() async {
    try {
      await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgMusicPlayer.play(AssetSource('garden/music.mp3'));
    } catch (e) {
      GardenErrorHandler.handleAudioError('BackgroundMusic', e);
    }
  }

  void _setSeason() {
    final month = DateTime.now().month;
    currentSeason = switch (month) {
      3 || 4 || 5 => SeasonType.spring,
      6 || 7 || 8 => SeasonType.summer,
      9 || 10 || 11 => SeasonType.autumn,
      _ => SeasonType.winter,
    };
  }

  void _setWeatherType() {
    Random random = Random();
    weatherType = WeatherType.values[random.nextInt(WeatherType.values.length)];
  }

  void _startBeeVisitor() {
    _beeTimer = Timer.periodic(Duration(seconds: 8), (timer) {
      setState(() {
        showBee = !showBee;
        if (showBee) {
          beeX = Random().nextDouble() * 300;
          beeY = Random().nextDouble() * 200 + 100;
        }
      });
    });
  }

  void _startSnailVisitor() {
    _snailTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      setState(() {
        showSnail = !showSnail;
        if (showSnail) {
          snailX = Random().nextDouble() * 250;
        }
      });
    });
  }

  void _startRandomVisitor() {
    _visitorTimer = Timer.periodic(Duration(minutes: 3), (timer) {
      _addRandomReward();
    });
  }

  void _startGrowthChecker() {
    _growthCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkFlowerGrowth();
      _updateFlowerAges();
    });
  }

  void _startWeatherChanger() {
    _weatherTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _setWeatherType();
      setState(() {});
    });
  }

  void _startPestChecker() {
    _pestTimer = Timer.periodic(Duration(minutes: 10), (timer) {
      _checkForPests();
    });
  }

  void _checkForPests() {
    if (userGardens.isEmpty) return;
    
    CrystalGarden garden = userGardens[currentPageIndex];
    for (Flower flower in garden.flowers) {
      if (Random().nextDouble() < 0.1 && !flower.isPest) {
        flower.isPest = true;
        flower.health = max(10, flower.health - 30);
        _showPestAlert(flower);
        break; // Only one pest at a time
      }
    }
  }

  void _showPestAlert(Flower flower) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.bug_report, color: Colors.red),
            SizedBox(width: 8),
            Text("${flower.species} has pests! Use pesticide."),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'TREAT',
          onPressed: () => _treatPest(flower),
        ),
      ),
    );
  }

  void _treatPest(Flower flower) {
    CrystalGarden garden = userGardens[currentPageIndex];
    if (garden.useItem('pesticide', 1)) {
      flower.isPest = false;
      flower.health = min(100, flower.health + 20);
      _playEffect('garden/pest_treated.mp3');
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No pesticide available! Buy some in the shop.")),
      );
    }
  }

  void _addRandomReward() {
    if (userGardens.isEmpty) return;
    
    Random random = Random();
    CrystalGarden garden = userGardens[currentPageIndex];
    
    switch (random.nextInt(4)) {
      case 0:
        garden.coins += 10;
        _showRewardMessage("A fairy left you 10 coins! ✨");
        break;
      case 1:
        garden.gems += 1;
        _showRewardMessage("A unicorn left you 1 gem! 🦄");
        break;
      case 2:
        garden.addToInventory('fertilizer', 1);
        _showRewardMessage("A gnome left you fertilizer! 🧙‍♂️");
        break;
      case 3:
        garden.addToInventory('water', 2);
        _showRewardMessage("Rain clouds left you water! ☁️");
        break;
    }
    setState(() {});
  }

  void _showRewardMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  Future<void> _playEffect(String path) async {
    try {
      await _effectPlayer.play(AssetSource(path));
    } catch (e) {
      GardenErrorHandler.handleAudioError('EffectSound', e);
    }
  }

  void _updateFlowerAges() {
    if (userGardens.isEmpty) return;
    
    for (Flower flower in userGardens[currentPageIndex].flowers) {
      flower.updateAge();
    }
  }

  Widget _buildEnhancedWeatherEffect({required WeatherType weatherType}) {
    return AnimatedBuilder(
      animation: _weatherAnimation,
      builder: (context, child) {
        switch (weatherType) {
          case WeatherType.rainy:
            return CustomPaint(painter: EnhancedRainPainter(_weatherAnimation.value));
          case WeatherType.snowy:
            return CustomPaint(painter: EnhancedSnowPainter(_weatherAnimation.value));
          case WeatherType.windy:
            return CustomPaint(painter: WindyPainter(_weatherAnimation.value));
          case WeatherType.misty:
            return CustomPaint(painter: MistyPainter(_weatherAnimation.value));
          case WeatherType.sunny:
            return CustomPaint(painter: SunnyPainter(_weatherAnimation.value));
        }
      },
    );
  }

  Future<void> _loadCoinBalance() async {
    setState(() {
      if (userGardens.isNotEmpty) {
        userGardens[0].coins = 150;
        userGardens[0].gems = 5;
      }
    });
  }

  Future<void> _addCoins(int amount) async {
    if (userGardens.isNotEmpty) {
      userGardens[0].coins += amount;
      setState(() {});
    }
  }

  Future<void> _addGems(int amount) async {
    if (userGardens.isNotEmpty) {
      userGardens[0].gems += amount;
      setState(() {});
    }
  }

  void _giveRewardsForBloom(Flower flower) {
    int coins = switch (flower.rarity) {
      FlowerRarity.common => 15,
      FlowerRarity.rare => 50,
      FlowerRarity.epic => 100,
    };
    
    int gems = switch (flower.rarity) {
      FlowerRarity.common => 0,
      FlowerRarity.rare => 1,
      FlowerRarity.epic => 2,
    };
    
    int experience = switch (flower.rarity) {
      FlowerRarity.common => 10,
      FlowerRarity.rare => 40,
      FlowerRarity.epic => 80,
    };

    _addCoins(coins);
    _addGems(gems);
    userGardens[currentPageIndex].addExperience(experience);
    
    String message = "🌸 ${flower.species} bloomed! +$coins coins";
    if (gems > 0) message += ", +$gems gems";
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: flower.rarity == FlowerRarity.epic 
          ? Colors.purple.shade700 
          : Colors.green.shade600,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _playFlowerSong(Flower flower) async {
    // All flowers use the same song pool regardless of rarity
    List<String> songOptions = [
      'garden/songs/1.mp3', 'garden/songs/2.mp3', 'garden/songs/3.mp3',
      'garden/songs/4.mp3', 'garden/songs/5.mp3', 'garden/songs/6.mp3',
      'garden/songs/7.mp3', 'garden/songs/8.mp3', 'garden/songs/9.mp3',
      'garden/songs/10.mp3', 'garden/songs/11.mp3', 'garden/songs/12.mp3',
      'garden/songs/13.mp3', 'garden/songs/14.mp3', 'garden/songs/15.mp3',
      'garden/songs/16.mp3', 'garden/songs/17.mp3', 'garden/songs/18.mp3',
      'garden/songs/19.mp3', 'garden/songs/20.mp3', 'garden/songs/21.mp3',
      'garden/songs/22.mp3', 'garden/songs/23.mp3', 'garden/songs/24.mp3',
      'garden/songs/25.mp3', 'garden/songs/26.mp3', 'garden/songs/27.mp3',
      'garden/songs/28.mp3', 'garden/songs/29.mp3', 'garden/songs/30.mp3',
      'garden/songs/31.mp3', 'garden/songs/32.mp3', 'garden/songs/33.mp3',
    ];
    
    Random random = Random();
    String selectedSong = songOptions[random.nextInt(songOptions.length)];
    
    try {
      await _songPlayer.play(AssetSource(selectedSong));
    } catch (e) {
      GardenErrorHandler.handleAudioError('BloomSong', e);
    }
  }

  void _checkFlowerGrowth() {
    if (userGardens.isEmpty) return;
    
    bool anyFlowerBloomed = false;
    for (Flower flower in userGardens[currentPageIndex].flowers) {
      if (flower.tryToGrow() && !flower.hasBloomedAndSung) {
        flower.hasBloomedAndSung = true;
        _giveRewardsForBloom(flower);
        _playFlowerSong(flower);
        anyFlowerBloomed = true;
      }
    }
    
    if (anyFlowerBloomed) {
      _confettiController.play();
      HapticFeedback.mediumImpact();
      setState(() {});
    }
  }

  void _createNewGarden() {
    String nextBackground = gardenBackgrounds[userGardens.length % gardenBackgrounds.length];
    GardenTheme theme = GardenTheme.values[userGardens.length % GardenTheme.values.length];
    
    CrystalGarden newGarden = CrystalGarden(
      backgroundImage: nextBackground,
      theme: theme,
      season: currentSeason,
    );
    
    // Add initial flowers
    Random random = Random();
    for (int i = 0; i < 3; i++) {
      FlowerRarity rarity = _getRandomRarity();
      Flower flower = Flower(
        id: 'flower_${DateTime.now().millisecondsSinceEpoch}_$i',
        imagePath: 'flower_${i + 1}.webp',
        rarity: rarity,
        species: _getRandomSpecies(),
        xPosition: 50.0 + (i * 80.0),
        yPosition: 200.0 + (random.nextDouble() * 80),
      );
      newGarden.addFlower(flower);
    }
    
    setState(() {
      userGardens.add(newGarden);
    });

    _addCoins(75);
    _addGems(1);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("New ${theme.name.toUpperCase()} Garden Created! +75 coins, +1 gem"),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.purple.shade600,
      ),
    );

    _confettiController.play();
  }

  FlowerRarity _getRandomRarity() {
    Random random = Random();
    double roll = random.nextDouble();
    
    if (roll < 0.6) return FlowerRarity.common;
    if (roll < 0.9) return FlowerRarity.rare;
    return FlowerRarity.epic;
  }

  String _getRandomSpecies() {
    List<String> species = [
      'Rose', 'Tulip', 'Sunflower', 'Lily', 'Daisy', 
      'Orchid', 'Peony', 'Iris', 'Poppy', 'Lavender'
    ];
    return species[Random().nextInt(species.length)];
  }

  void _onAction(int flowerIndex) async {
    if (userGardens.isEmpty) return;
    
    CrystalGarden currentGarden = userGardens[currentPageIndex];
    if (flowerIndex >= currentGarden.flowers.length) return;
    
    Flower flower = currentGarden.flowers[flowerIndex];
    
    switch (_selectedTool) {
      case 'water':
        await _onWater(flowerIndex);
        break;
      case 'fertilizer':
        await _onFertilize(flowerIndex);
        break;
      case 'pesticide':
        await _onTreatPest(flowerIndex);
        break;
    }
  }

  Future<void> _onWater(int flowerIndex) async {
    if (!canWater || userGardens.isEmpty) return;
    
    CrystalGarden currentGarden = userGardens[currentPageIndex];
    if (!currentGarden.useItem('water', 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No water available! Buy more in the shop.")),
      );
      return;
    }
    
    Flower flower = currentGarden.flowers[flowerIndex];
    
    setState(() {
      _watering = true;
      _wateringFlowerIndex = flowerIndex;
      _lastWaterTime = DateTime.now();
    });
    
    flower.water();
    _playEffect('garden/water_pour.mp3');
    
    await Future.delayed(Duration(seconds: 2));
    
    setState(() {
      _watering = false;
      _wateringFlowerIndex = null;
    });
    
    _addCoins(20);
    currentGarden.addExperience(5);
    
    // Weather bonus
    if (weatherType == WeatherType.sunny) {
      _addCoins(5);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sunny weather bonus! +25 coins total"), duration: Duration(seconds: 2)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${flower.species} watered! +20 coins"), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _onFertilize(int flowerIndex) async {
    if (!canFertilize || userGardens.isEmpty) return;
    
    CrystalGarden currentGarden = userGardens[currentPageIndex];
    if (!currentGarden.useItem('fertilizer', 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No fertilizer available! Buy more in the shop.")),
      );
      return;
    }
    
    Flower flower = currentGarden.flowers[flowerIndex];
    
    setState(() {
      _fertilizing = true;
      _lastFertilizerTime = DateTime.now();
    });
    
    flower.fertilize();
    _playEffect('garden/fertilize.mp3');
    
    await Future.delayed(Duration(seconds: 1));
    
    setState(() {
      _fertilizing = false;
    });
    
    _addCoins(30);
    currentGarden.addExperience(10);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${flower.species} fertilized! +30 coins"), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _onTreatPest(int flowerIndex) async {
    CrystalGarden currentGarden = userGardens[currentPageIndex];
    Flower flower = currentGarden.flowers[flowerIndex];
    
    if (!flower.isPest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("This flower doesn't have pests!")),
      );
      return;
    }
    
    _treatPest(flower);
  }

  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolButton('water', Icons.water_drop, canWater),
          SizedBox(width: 8),
          _buildToolButton('fertilizer', Icons.eco, canFertilize),
          SizedBox(width: 8),
          _buildToolButton('pesticide', Icons.bug_report, true),
        ],
      ),
    );
  }

  Widget _buildToolButton(String tool, IconData icon, bool enabled) {
    bool isSelected = _selectedTool == tool;
    
    // Map tools to their image assets
    String? imagePath;
    switch (tool) {
      case 'water':
        imagePath = 'assets/garden/watering_can.webp';
        break;
      case 'fertilizer':
        imagePath = 'assets/garden/fertilizer.png';
        break;
      case 'pesticide':
        imagePath = 'assets/garden/pesticide.webp';
        break;
    }
    
    return GestureDetector(
      onTap: enabled ? () => setState(() => _selectedTool = tool) : null,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.blue) : null,
        ),
        child: imagePath != null 
          ? Image.asset(
              imagePath,
              width: 24,
              height: 24,
              color: enabled ? (isSelected ? Colors.blue : Colors.grey.shade700) : Colors.grey.shade400,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to icon if image not found
                return Icon(
                  icon,
                  color: enabled ? (isSelected ? Colors.blue : Colors.grey.shade700) : Colors.grey.shade400,
                  size: 24,
                );
              },
            )
          : Icon(
              icon,
              color: enabled ? (isSelected ? Colors.blue : Colors.grey.shade700) : Colors.grey.shade400,
              size: 24,
            ),
      ),
    );
  }

  Widget _buildStatsPanel() {
    if (userGardens.isEmpty) return SizedBox();
    
    CrystalGarden garden = userGardens[currentPageIndex];
    
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Garden Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => setState(() => _showStats = false),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Level', '${garden.level}', Colors.purple),
              _buildStatItem('Exp', '${garden.experience}', Colors.blue),
              _buildStatItem('Flowers', '${garden.flowers.length}', Colors.green),
            ],
          ),
          SizedBox(height: 15),
          Text('Inventory:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Wrap(
            spacing: 8,
            children: garden.inventory.entries.map((entry) {
              return Chip(
                label: Text('${entry.key}: ${entry.value}'),
                backgroundColor: Colors.blue.shade50,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildShopPanel() {
    if (userGardens.isEmpty) return SizedBox();
    
    CrystalGarden garden = userGardens[currentPageIndex];
    
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Garden Shop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => setState(() => _showShop = false),
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildShopItem('Water (5x)', 25, 'coins', () => _buyItem('water', 5, 25, 'coins')),
          _buildShopItem('Fertilizer (3x)', 50, 'coins', () => _buyItem('fertilizer', 3, 50, 'coins')),
          _buildShopItem('Pesticide (2x)', 75, 'coins', () => _buyItem('pesticide', 2, 75, 'coins')),
          _buildShopItem('Rare Seeds (1x)', 2, 'gems', () => _buyItem('seeds_rare', 1, 2, 'gems')),
        ],
      ),
    );
  }

  Widget _buildShopItem(String item, int price, String currency, VoidCallback onBuy) {
    return Card(
      child: ListTile(
        title: Text(item),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$price'),
            Icon(currency == 'coins' ? Icons.monetization_on : Icons.diamond, 
                 color: currency == 'coins' ? Colors.yellow.shade700 : Colors.blue),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: onBuy,
              child: Text('Buy'),
            ),
          ],
        ),
      ),
    );
  }

  void _buyItem(String item, int quantity, int price, String currency) {
    CrystalGarden garden = userGardens[currentPageIndex];
    
    bool canAfford = currency == 'coins' ? 
      garden.coins >= price : garden.gems >= price;
    
    if (!canAfford) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Not enough $currency!")),
      );
      return;
    }
    
    if (currency == 'coins') {
      garden.coins -= price;
    } else {
      garden.gems -= price;
    }
    
    garden.addToInventory(item, quantity);
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Purchased $item x$quantity!")),
    );
  }

  Widget _buildGardenView(CrystalGarden garden) {
    if (garden.flowers.isEmpty) {
      Random random = Random();
      for (int i = 0; i < 3; i++) {
        FlowerRarity rarity = _getRandomRarity();
        Flower flower = Flower(
          id: 'flower_${DateTime.now().millisecondsSinceEpoch}_$i',
          imagePath: 'flower_${i + 1}.webp',
          rarity: rarity,
          species: _getRandomSpecies(),
          xPosition: 50.0 + (i * 80.0),
          yPosition: 200.0 + (random.nextDouble() * 80),
        );
        garden.addFlower(flower);
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background with seasonal tint
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            _getSeasonalTint().withOpacity(0.2),
            BlendMode.overlay,
          ),
          child: Image.asset(
            garden.backgroundImage,
            fit: BoxFit.cover,
          ),
        ),
        
        // Main garden content
        Column(
          children: [
            // Top bar with currency and level
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.yellow.shade700),
                      Text(' ${garden.coins}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(width: 16),
                      Icon(Icons.diamond, color: Colors.blue),
                      Text(' ${garden.gems}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Lv.${garden.level}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.analytics),
                        onPressed: () => setState(() => _showStats = true),
                      ),
                      IconButton(
                        icon: Icon(Icons.shopping_cart),
                        onPressed: () => setState(() => _showShop = true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Flowers area
            Expanded(
              child: Stack(
                children: [
                  // Flowers
                  ...List.generate(garden.flowers.length, (i) {
                    return Positioned(
                      left: garden.flowers[i].xPosition,
                      top: garden.flowers[i].yPosition,
                      child: DragTarget<String>(
                        builder: (context, candidateData, rejectedData) {
                          return GestureDetector(
                            onTap: () => _onAction(i),
                            child: _buildEnhancedFlower(garden.flowers[i], i),
                          );
                        },
                        onWillAcceptWithDetails: (data) => true,
                        onAcceptWithDetails: (data) => _onAction(i),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getSeasonalTint() {
    switch (currentSeason) {
      case SeasonType.spring: return Colors.green;
      case SeasonType.summer: return Colors.yellow;
      case SeasonType.autumn: return Colors.orange;
      case SeasonType.winter: return Colors.blue;
    }
  }

  Widget _buildEnhancedFlower(Flower flower, int index) {
    double baseSize = 180.0;
    double baseHeight = 270.0;
    
    double currentWidth = baseSize * flower.currentSize;
    double currentHeight = baseHeight * flower.currentSize;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 800),
      child: Stack(
        children: [
          // Main flower image
          Image.asset(
            flower.currentImagePath,
            width: currentWidth,
            height: currentHeight,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/garden/flowers/common/flower_1.webp',
                width: currentWidth,
                height: currentHeight,
              );
            },
          ),
          
          // Status indicators
          Positioned(
            top: 5,
            right: 5,
            child: Column(
              children: [
                if (flower.needsWater)
                  Icon(Icons.water_drop_outlined, color: Colors.blue, size: 20),
                if (flower.needsFertilizer)
                  Icon(Icons.eco_outlined, color: Colors.green, size: 20),
                if (flower.isPest)
                  Icon(Icons.bug_report, color: Colors.red, size: 20),
              ],
            ),
          ),
          
          // Health bar
          Positioned(
            bottom: 5,
            left: 5,
            right: 5,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                widthFactor: flower.health / 100,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: flower.healthColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          
          // Watering animation
          if (_watering && _wateringFlowerIndex == index)
            Positioned(
              top: -10,
              left: currentWidth / 2 - 15,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 500),
                child: Icon(Icons.water_drop, color: Colors.blueAccent, size: 30),
              ),
            ),
          
          // Rarity border
          if (flower.rarity != FlowerRarity.common)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(currentWidth / 2),
                  border: Border.all(
                    color: _getRarityColor(flower.rarity).withOpacity(0.6),
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getRarityColor(FlowerRarity rarity) {
    switch (rarity) {
      case FlowerRarity.common: return Colors.grey;
      case FlowerRarity.rare: return Colors.blue;
      case FlowerRarity.epic: return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text("CrystalGarden™ "),
            Icon(_getSeasonIcon()),
            Text(" ${weatherType.name.toUpperCase()}"),
          ],
        ),
        backgroundColor: _getSeasonalTint().withOpacity(0.1),
      ),
      body: Stack(
        children: [
          // Main garden view
          PageView.builder(
            itemCount: userGardens.length,
            onPageChanged: (index) {
              setState(() => currentPageIndex = index);
              if (index == userGardens.length - 1) {
                _createNewGarden();
              }
            },
            controller: PageController(initialPage: currentPageIndex),
            itemBuilder: (context, index) {
              return _buildGardenView(userGardens[index]);
            },
          ),
          
          // Weather overlay
          Positioned.fill(
            child: IgnorePointer(
              child: _buildEnhancedWeatherEffect(weatherType: weatherType),
            ),
          ),
          
          // Toolbar
          Positioned(
            top: 100,
            left: MediaQuery.of(context).size.width / 2 - 80,
            child: _buildToolbar(),
          ),
          
          // Visitors
          if (showBee)
            AnimatedPositioned(
              duration: Duration(milliseconds: 200),
              left: beeX,
              top: beeY,
              child: GestureDetector(
                onTap: () {
                  _addCoins(5);
                  setState(() => showBee = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Bee gave you 5 coins! 🐝")),
                  );
                },
                child: Image.asset('assets/garden/bugs/bee.png', width: 40, height: 40),
              ),
            ),
          
          if (showSnail)
            AnimatedPositioned(
              duration: Duration(milliseconds: 600),
              left: snailX,
              top: MediaQuery.of(context).size.height - 120,
              child: GestureDetector(
                onTap: () {
                  if (userGardens.isNotEmpty) {
                    userGardens[currentPageIndex].addToInventory('fertilizer', 1);
                  }
                  setState(() => showSnail = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Snail gave you fertilizer! 🐌")),
                  );
                },
                child: Image.asset('assets/garden/bugs/snail.png', width: 50, height: 35),
              ),
            ),
          
          // Stats panel
          if (_showStats)
            _buildStatsPanel(),
          
          // Shop panel
          if (_showShop)
            _buildShopPanel(),
          
          // Confetti
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.red, Colors.green, Colors.blue, Colors.purple, Colors.orange],
            createParticlePath: (size) {
              return Path()
                ..lineTo(size.width / 2, size.height / 2)
                ..lineTo(size.width, size.height);
            },
          ),
        ],
      ),
    );
  }

  IconData _getSeasonIcon() {
    switch (currentSeason) {
      case SeasonType.spring: return Icons.local_florist;
      case SeasonType.summer: return Icons.wb_sunny;
      case SeasonType.autumn: return Icons.nature;
      case SeasonType.winter: return Icons.ac_unit;
    }
  }
}

// Enhanced weather painters
class EnhancedRainPainter extends CustomPainter {
  final double animationValue;
  EnhancedRainPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..strokeWidth = 2;

    final random = Random(42); // Fixed seed for consistent pattern
    for (int i = 0; i < 150; i++) {
      final x = (random.nextDouble() * size.width + animationValue * 50) % size.width;
      final y = (random.nextDouble() * size.height + animationValue * 100) % size.height;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 8, y + 25),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class EnhancedSnowPainter extends CustomPainter {
  final double animationValue;
  EnhancedSnowPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.9);

    final random = Random(123);
    for (int i = 0; i < 80; i++) {
      final x = (random.nextDouble() * size.width + animationValue * 20) % size.width;
      final y = (random.nextDouble() * size.height + animationValue * 30) % size.height;
      final radius = 2 + random.nextDouble() * 3;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WindyPainter extends CustomPainter {
  final double animationValue;
  WindyPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    for (int i = 0; i < 30; i++) {
      final y = i * (size.height / 30);
      final wave = sin(animationValue * 2 * pi + i * 0.5) * 20;
      canvas.drawLine(
        Offset(0, y + wave),
        Offset(size.width, y + wave + 10),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MistyPainter extends CustomPainter {
  final double animationValue;
  MistyPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.withOpacity(0.3);

    final random = Random(456);
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = size.height * 0.7 + random.nextDouble() * size.height * 0.3;
      final radius = 30 + random.nextDouble() * 50 + sin(animationValue * 2 * pi) * 10;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SunnyPainter extends CustomPainter {
  final double animationValue;
  SunnyPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.yellow.withOpacity(0.1);

    // Sun rays
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + (animationValue * 2 * pi);
      final startX = size.width * 0.8 + cos(angle) * 30;
      final startY = size.height * 0.2 + sin(angle) * 30;
      final endX = size.width * 0.8 + cos(angle) * 60;
      final endY = size.height * 0.2 + sin(angle) * 60;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
