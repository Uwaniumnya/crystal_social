import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'profile_provider.dart';

class EnhancedEditProfileScreen extends StatefulWidget {
  final String userId;

  const EnhancedEditProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<EnhancedEditProfileScreen> createState() => _EnhancedEditProfileScreenState();
}

class _EnhancedEditProfileScreenState extends State<EnhancedEditProfileScreen> 
    with TickerProviderStateMixin, ProfileMixin {

  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _displayNameController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  late TextEditingController _instagramController;
  late TextEditingController _twitterController;
  
  File? _newAvatarFile;
  bool _isSaving = false;
  String? selectedZodiacSign;
  List<String> selectedInterests = [];
  bool _isPrivateProfile = false;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> zodiacSigns = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  final List<String> interestOptions = [
    'Music', 'Movies', 'Gaming', 'Art', 'Travel', 'Food',
    'Sports', 'Reading', 'Photography', 'Technology', 'Nature', 'Fashion'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _loadProfileData();
  }

  void _initializeControllers() {
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _displayNameController = TextEditingController();
    _locationController = TextEditingController();
    _websiteController = TextEditingController();
    _instagramController = TextEditingController();
    _twitterController = TextEditingController();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  Future<void> _loadProfileData() async {
    await profileProvider.initialize(widget.userId);
    
    if (mounted) {
      setState(() {
        _usernameController.text = profileProvider.username ?? '';
        _bioController.text = profileProvider.bio ?? '';
        _displayNameController.text = profileProvider.displayName ?? '';
        _locationController.text = profileProvider.location ?? '';
        _websiteController.text = profileProvider.website ?? '';
        selectedZodiacSign = profileProvider.zodiacSign;
        selectedInterests = List.from(profileProvider.interests ?? []);
        _isPrivateProfile = profileProvider.isPrivateProfile;
        
        // Load social links
        final socialLinks = profileProvider.socialLinks;
        if (socialLinks != null) {
          _instagramController.text = socialLinks['instagram'] ?? '';
          _twitterController.text = socialLinks['twitter'] ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _displayNameController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF16213e),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save, color: Colors.white),
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildAvatarSection(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildAdditionalInfoSection(),
              const SizedBox(height: 24),
              _buildInterestsSection(),
              const SizedBox(height: 24),
              _buildSocialLinksSection(),
              const SizedBox(height: 24),
              _buildPrivacySection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Profile Picture',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _getAvatarImage(),
                  child: _getAvatarImage() == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to change avatar',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getAvatarImage() {
    if (_newAvatarFile != null) {
      return FileImage(_newAvatarFile!);
    } else if (profileProvider.avatarUrl != null) {
      return NetworkImage(profileProvider.avatarUrl!);
    }
    return null;
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _displayNameController,
            label: 'Display Name',
            icon: Icons.badge,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bioController,
            label: 'Bio',
            icon: Icons.description,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _locationController,
            label: 'Location',
            icon: Icons.location_on,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _websiteController,
            label: 'Website',
            icon: Icons.link,
          ),
          const SizedBox(height: 16),
          _buildZodiacSelector(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFF1a1a2e),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildZodiacSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zodiac Sign',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedZodiacSign,
              hint: Text(
                'Select your zodiac sign',
                style: TextStyle(color: Colors.grey[400]),
              ),
              dropdownColor: const Color(0xFF1a1a2e),
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(
                    'None',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                ...zodiacSigns.map((sign) => DropdownMenuItem(
                  value: sign,
                  child: Text(sign),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  selectedZodiacSign = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interests',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interestOptions.map((interest) {
              final isSelected = selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedInterests.remove(interest);
                    } else {
                      selectedInterests.add(interest);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : const Color(0xFF1a1a2e),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[600]!,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinksSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Social Links',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _instagramController,
            label: 'Instagram',
            icon: Icons.camera_alt,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _twitterController,
            label: 'Twitter',
            icon: Icons.alternate_email,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Privacy Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(
              'Private Profile',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Only approved followers can see your profile',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            value: _isPrivateProfile,
            onChanged: (value) {
              setState(() {
                _isPrivateProfile = value;
              });
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _newAvatarFile = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Upload avatar if changed
      String? newAvatarUrl;
      if (_newAvatarFile != null) {
        newAvatarUrl = await profileProvider.uploadAvatar(_newAvatarFile!);
      }

      // Prepare social links
      final socialLinks = <String, dynamic>{};
      if (_instagramController.text.isNotEmpty) {
        socialLinks['instagram'] = _instagramController.text;
      }
      if (_twitterController.text.isNotEmpty) {
        socialLinks['twitter'] = _twitterController.text;
      }

      // Prepare update data
      final updates = <String, dynamic>{};
      
      if (_usernameController.text.isNotEmpty) {
        updates['username'] = _usernameController.text;
      }
      if (_displayNameController.text.isNotEmpty) {
        updates['display_name'] = _displayNameController.text;
      }
      if (_bioController.text.isNotEmpty) {
        updates['bio'] = _bioController.text;
      }
      if (_locationController.text.isNotEmpty) {
        updates['location'] = _locationController.text;
      }
      if (_websiteController.text.isNotEmpty) {
        updates['website'] = _websiteController.text;
      }
      if (selectedZodiacSign != null) {
        updates['zodiac_sign'] = selectedZodiacSign;
      }
      if (selectedInterests.isNotEmpty) {
        updates['interests'] = selectedInterests;
      }
      if (socialLinks.isNotEmpty) {
        updates['social_links'] = socialLinks;
      }
      if (newAvatarUrl != null) {
        updates['avatarUrl'] = newAvatarUrl;
      }
      updates['is_private'] = _isPrivateProfile;

      // Update profile
      final success = await profileProvider.updateProfile(updates);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

// Keep original EditProfileScreen as wrapper for backward compatibility
class EditProfileScreen extends StatelessWidget {
  final String userId;
  final String currentUsername;
  final String? currentBio;
  final String? currentAvatarUrl;
  final String? currentZodiacSign;
  final List<String>? currentInterests;
  final Map<String, dynamic>? socialLinks;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.currentUsername,
    this.currentBio,
    this.currentAvatarUrl,
    this.currentZodiacSign,
    this.currentInterests,
    this.socialLinks,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider(),
      child: EnhancedEditProfileScreen(userId: userId),
    );
  }
}
