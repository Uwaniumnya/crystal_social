// File: pet_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'updated_pet_list.dart';
import 'pet_state_provider.dart';
import 'pet_care_screen.dart';
import 'global_accessory_system.dart';

class PetDetailsScreen extends StatefulWidget {
  final String? userId;
  
  const PetDetailsScreen({super.key, this.userId});

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> 
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _inventoryAccessories = [];
  bool _isLoading = false;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _nameController = TextEditingController();
  final PageController _pageController = PageController();
  
  // Animation controllers
  late AnimationController _petAnimationController;
  late AnimationController _statsAnimationController;
  late AnimationController _accessoryAnimationController;
  late ConfettiController _confettiController;
  
  int _currentPage = 0;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
    if (widget.userId != null) {
      _loadAccessoriesFromInventory();
    }
    _startIdleAnimations();
  }

  void _initializeAnimations() {
    // Pet animation (gentle breathing/floating effect)
    _petAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Stats animation (slide in from right)
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Accessory animation (bounce effect when selected)
    _accessoryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Confetti for achievements
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  void _initializeControllers() {
    final petState = Provider.of<PetState>(context, listen: false);
    _nameController.text = petState.petName;
    _nameController.addListener(() {
      petState.updatePet(name: _nameController.text);
    });
  }

  void _startIdleAnimations() {
    _petAnimationController.repeat(reverse: true);
    _statsAnimationController.forward();
  }

  Future<void> _loadAccessoriesFromInventory() async {
    setState(() => _isLoading = true);
    
    try {
      final petState = Provider.of<PetState>(context, listen: false);
      
      // Get only unlocked accessories from the global system
      final unlockedAccessories = GlobalAccessoryUtils.getOwnedAccessories(petState.unlockedAccessories)
          .map((accessory) => {
            'id': accessory.id,
            'name': accessory.name,
            'type': 'pet_accessory',
            'category': accessory.category.toString().split('.').last,
            'rarity': accessory.rarity.toString().split('.').last,
            'icon_asset': accessory.iconAsset,
          })
          .toList();
      
      setState(() {
        _inventoryAccessories = unlockedAccessories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading accessories: $e');
    }
  }

  String _getPetImagePath(PetState petState, Pet pet, {String? previewAccessory}) {
    final accessory = previewAccessory ?? petState.selectedAccessory;
    if (accessory == 'None' || accessory.isEmpty) {
      return pet.assetPath;
    }
    // Use the Pet model's new accessory system
    return pet.getAssetPathWithAccessory(accessory);
  }

  void _playSound(String fileName) async {
    try {
      await _audioPlayer.play(AssetSource('pets/sounds/$fileName'));
    } catch (e) {
      debugPrint('Could not play sound: $fileName');
    }
  }

  void _onPetSelected(String petId) {
    _playSound('pet_select.mp3');
    HapticFeedback.selectionClick();
    
    // Animate pet change
    _petAnimationController.forward().then((_) {
      Provider.of<PetState>(context, listen: false).selectPet(petId);
      _petAnimationController.reverse();
    });

    // Trigger confetti for first pet selection
    final petState = Provider.of<PetState>(context, listen: false);
    if (petState.totalInteractions == 0) {
      _confettiController.play();
    }
  }

  void _onAccessorySelected(String accessory) {
    _playSound('accessory_equip.mp3');
    HapticFeedback.mediumImpact();
    
    // Animate accessory change
    _accessoryAnimationController.forward().then((_) {
      if (accessory == 'None') {
        Provider.of<PetState>(context, listen: false).removeAccessory();
      } else {
        Provider.of<PetState>(context, listen: false).equipAccessory(accessory);
      }
      _accessoryAnimationController.reverse();
    });
  }

  void _showPetPreview(Pet pet) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pet.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.purple.shade100, Colors.pink.shade100],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Image.asset(
                    pet.assetPath,
                    width: 150,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.pets, size: 100, color: Colors.purple.shade300);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                pet.speechLines.isNotEmpty 
                    ? pet.speechLines[0] 
                    : 'A wonderful companion!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _onPetSelected(pet.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Select'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Pet> _getFilteredPets() {
    if (_selectedCategory == 'All') return availablePets;
    return availablePets.where((pet) {
      switch (_selectedCategory) {
        case 'Real':
          return ['cat', 'dog', 'rabbit', 'bird'].contains(pet.id);
        case 'Fictional':
          return ['dragon', 'unicorn', 'phoenix'].contains(pet.id);
        case 'Mythical':
          return ['griffin', 'pegasus', 'sphinx'].contains(pet.id);
        default:
          return true;
      }
    }).toList();
  }

  void _navigateToCareScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetCareScreen(userId: widget.userId),
      ),
    );
  }

  @override
  void dispose() {
    _petAnimationController.dispose();
    _statsAnimationController.dispose();
    _accessoryAnimationController.dispose();
    _confettiController.dispose();
    _nameController.dispose();
    _pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petState = Provider.of<PetState>(context);
    final pet = availablePets.firstWhere((p) => p.id == petState.selectedPetId);
    final filteredPets = _getFilteredPets();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade300,
              Colors.pink.shade300,
              Colors.blue.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Confetti effect
              Positioned.fill(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [Colors.pink, Colors.purple, Colors.yellow, Colors.blue],
                ),
              ),

              // Main content
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPetSelectionPage(petState, pet, filteredPets),
                  _buildCustomizationPage(petState, pet),
                  _buildStatsAndSettingsPage(petState),
                ],
              ),

              // App bar
              _buildCustomAppBar(),

              // Page indicators
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index 
                            ? Colors.white 
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

              // Care button (floating)
              Positioned(
                bottom: 80,
                right: 20,
                child: FloatingActionButton.extended(
                  onPressed: _navigateToCareScreen,
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.pets),
                  label: const Text('Care'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.9),
              Colors.white.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
            ),
            const Expanded(
              child: Text(
                "Pet Companion",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                _playSound('ui_click.mp3');
                // Future: Add help dialog
              },
              icon: const Icon(Icons.help_outline, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetSelectionPage(PetState petState, Pet pet, List<Pet> filteredPets) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet preview section
            Center(
              child: AnimatedBuilder(
                animation: _petAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_petAnimationController.value * 0.1),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            _getPetImagePath(petState, pet),
                            width: 120,
                            height: 120,
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.pets, size: 60, color: Colors.purple[300]),
                                  Text('Image not found', 
                                       style: TextStyle(color: Colors.purple[300])),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Pet name section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "🐾 Pet Name",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(text: petState.petName),
                      decoration: InputDecoration(
                        labelText: "Give your pet a name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: const Icon(Icons.edit),
                      ),
                      onChanged: (val) => petState.updatePet(name: val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pet selection section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "✨ Choose Your Pet",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.filter_list),
                          onSelected: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                          itemBuilder: (context) => [
                            'All',
                            'Cute',
                            'Magical',
                            'Rare'
                          ].map((category) {
                            return PopupMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: filteredPets.length,
                      itemBuilder: (context, index) {
                        final petOption = filteredPets[index];
                        final isSelected = petState.selectedPetId == petOption.id;
                        
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.purple[100] : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected ? Colors.purple : Colors.grey[300]!,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.purple.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () => _onPetSelected(petOption.name),
                            borderRadius: BorderRadius.circular(15),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/pets/${petOption.name.toLowerCase()}.png',
                                    width: 50,
                                    height: 50,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.pets,
                                        size: 50,
                                        color: Colors.purple[300],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    petOption.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.purple[800] : Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizationPage(PetState petState, Pet pet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "🎀 Accessory Preview",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showPetPreview(pet),
                          icon: const Icon(Icons.visibility),
                          label: const Text("Preview"),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Future: Toggle preview mode
                            _playSound('ui_click.mp3');
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text("Preview Mode"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Inventory accessories
            if (_inventoryAccessories.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "👑 Your Collection",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _inventoryAccessories.map((item) {
                            final accessoryName = item['accessory_type'] ?? item['name'] ?? 'Unknown';
                            final isSelected = petState.selectedAccessory == accessoryName;
                            
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: FilterChip(
                                label: Text(accessoryName),
                                selected: isSelected,
                                onSelected: (_) => _onAccessorySelected(accessoryName),
                                selectedColor: Colors.purple[200],
                                checkmarkColor: Colors.purple[800],
                                avatar: isSelected ? null : const Icon(Icons.star, size: 16),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Default accessories
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "🎁 Basic Accessories",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ["None", "Bow", "Hat", "Scarf"].map((item) {
                        final isSelected = petState.selectedAccessory == item;
                        
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: FilterChip(
                            label: Text(item),
                            selected: isSelected,
                            onSelected: (_) => _onAccessorySelected(item),
                            selectedColor: Colors.blue[200],
                            checkmarkColor: Colors.blue[800],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsAndSettingsPage(PetState petState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "📊 Pet Statistics",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Bond level
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Bond Level: ${petState.bondLevel}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "XP: ${petState.bondXP}/100",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: petState.bondXP / 100,
                      backgroundColor: Colors.purple[100],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 20),

                    // Health stats
                    _buildStatRow("💖 Health", petState.health, Colors.red),
                    const SizedBox(height: 12),
                    _buildStatRow("😊 Happiness", petState.happiness, Colors.orange),
                    const SizedBox(height: 12),
                    _buildStatRow("⚡ Energy", petState.energy, Colors.blue),
                    const SizedBox(height: 12),
                    _buildStatRow("🍎 Hunger", 100 - petState.energy, Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settings section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "⚙️ Pet Settings",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text("🔇 Mute Pet Sounds"),
                      subtitle: const Text("Disable all pet sound effects"),
                      value: petState.isMuted,
                      onChanged: (val) {
                        petState.updatePet(muted: val);
                        _playSound('ui_click.mp3');
                      },
                      activeColor: Colors.purple,
                    ),
                    
                    const Divider(),
                    
                    SwitchListTile(
                      title: const Text("🧸 Activate Pet"),
                      subtitle: const Text("Enable pet companion features"),
                      value: petState.isEnabled,
                      onChanged: (val) {
                        petState.updatePet(enabled: val);
                        _playSound('ui_click.mp3');
                        if (val) {
                          _triggerConfetti();
                        }
                      },
                      activeColor: Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "🎮 Quick Actions",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _navigateToCareScreen,
                            icon: const Icon(Icons.pets),
                            label: const Text("Pet Care"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _playSound('ui_click.mp3');
                              // Future: Reset pet stats
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Reset feature coming soon!")),
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text("Reset"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text("${value.toInt()}/100", style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  void _triggerConfetti() {
    _confettiController.play();
  }
}
