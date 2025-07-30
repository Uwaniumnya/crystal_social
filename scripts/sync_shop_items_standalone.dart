import 'dart:convert';
import 'dart:io';

// Standalone shop item sync script with embedded data
void main() async {
  const supabaseUrl = 'https://zdsjtjbzhiejvpuahnlk.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkc2p0amJ6aGllanZwdWFobmxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MjAyMzYsImV4cCI6MjA2OTM5NjIzNn0.CSPzbngxKJHrHD8oNMFaYzvKXzNzMENFtaWu9Vy2rV0';
  
  final client = HttpClient();
  
  try {
    print('Starting shop item sync...');
    
    // Real pets with actual data from updated_pet_list.dart
    final pets = [
      {
        'name': 'Bubbles',
        'description': 'A bubbly axolotl that brings joy to your space',
        'price': 150,
        'image_url': 'assets/pets/pets/real/axolotl.png',
        'category_id': 3, // pets category
        'rarity': 'common',
        'tags': ['cute', 'aquatic', 'happy'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 5,
        'max_purchases': 1,
        'sort_order': 0,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Foxy',
        'description': 'A clever fox companion with fiery spirit',
        'price': 200,
        'image_url': 'assets/pets/pets/real/fox.png',
        'category_id': 3,
        'rarity': 'uncommon',
        'tags': ['clever', 'wild', 'spirit'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 8,
        'max_purchases': 1,
        'sort_order': 1,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Bamboo',
        'description': 'A peaceful panda that loves to relax',
        'price': 180,
        'image_url': 'assets/pets/pets/real/panda.png',
        'category_id': 3,
        'rarity': 'common',
        'tags': ['peaceful', 'zen', 'nature'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 6,
        'max_purchases': 1,
        'sort_order': 2,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Waddles',
        'description': 'An adorable penguin that waddles with style',
        'price': 170,
        'image_url': 'assets/pets/pets/real/penguin.png',
        'category_id': 3,
        'rarity': 'common',
        'tags': ['adorable', 'arctic', 'style'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 7,
        'max_purchases': 1,
        'sort_order': 3,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Bandit',
        'description': 'A mischievous raccoon with a mask of mystery',
        'price': 160,
        'image_url': 'assets/pets/pets/real/raccoon.png',
        'category_id': 3,
        'rarity': 'uncommon',
        'tags': ['mischievous', 'mystery', 'night'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 9,
        'max_purchases': 1,
        'sort_order': 4,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Trunk',
        'description': 'A wise elephant with a memory like no other',
        'price': 250,
        'image_url': 'assets/pets/pets/real/elephant.png',
        'category_id': 3,
        'rarity': 'rare',
        'tags': ['wise', 'memory', 'gentle'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 12,
        'max_purchases': 1,
        'sort_order': 5,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Spike',
        'description': 'A spiky hedgehog with a heart of gold',
        'price': 140,
        'image_url': 'assets/pets/pets/real/hedgehog.png',
        'category_id': 3,
        'rarity': 'common',
        'tags': ['spiky', 'heart', 'gold'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 4,
        'max_purchases': 1,
        'sort_order': 6,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Sleepy',
        'description': 'A sleepy koala that dreams of eucalyptus',
        'price': 190,
        'image_url': 'assets/pets/pets/real/koala.png',
        'category_id': 3,
        'rarity': 'uncommon',
        'tags': ['sleepy', 'dreams', 'eucalyptus'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 10,
        'max_purchases': 1,
        'sort_order': 7,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Splash',
        'description': 'A playful otter that loves to swim',
        'price': 165,
        'image_url': 'assets/pets/pets/real/otter.png',
        'category_id': 3,
        'rarity': 'common',
        'tags': ['playful', 'swim', 'water'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 6,
        'max_purchases': 1,
        'sort_order': 8,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Grace',
        'description': 'An elegant deer that moves with grace',
        'price': 175,
        'image_url': 'assets/pets/pets/real/deer.png',
        'category_id': 3,
        'rarity': 'uncommon',
        'tags': ['elegant', 'grace', 'forest'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 8,
        'max_purchases': 1,
        'sort_order': 9,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Echo',
        'description': 'A smart dolphin that echoes with wisdom',
        'price': 220,
        'image_url': 'assets/pets/pets/real/dolphin.png',
        'category_id': 3,
        'rarity': 'rare',
        'tags': ['smart', 'wisdom', 'ocean'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 11,
        'max_purchases': 1,
        'sort_order': 10,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Flipper',
        'description': 'A friendly seal that flips with joy',
        'price': 155,
        'image_url': 'assets/pets/pets/real/seal.png',
        'category_id': 3,
        'rarity': 'common',
        'tags': ['friendly', 'joy', 'marine'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 5,
        'max_purchases': 1,
        'sort_order': 11,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Inky',
        'description': 'A mysterious octopus with eight arms of wonder',
        'price': 230,
        'image_url': 'assets/pets/pets/real/octopus.png',
        'category_id': 3,
        'rarity': 'rare',
        'tags': ['mysterious', 'wonder', 'deep'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 13,
        'max_purchases': 1,
        'sort_order': 12,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Squeaky',
        'description': 'A small rat with a big personality',
        'price': 120,
        'image_url': 'assets/pets/pets/real/rat.png',
        'category_id': 3,
        'rarity': 'common',
        'tags': ['small', 'personality', 'clever'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 3,
        'max_purchases': 1,
        'sort_order': 13,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Glide',
        'description': 'A sugar glider that glides through dreams',
        'price': 185,
        'image_url': 'assets/pets/pets/real/sugar_glider.png',
        'category_id': 3,
        'rarity': 'uncommon',
        'tags': ['glide', 'dreams', 'sweet'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 9,
        'max_purchases': 1,
        'sort_order': 14,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Sandy',
        'description': 'A tiny fennec fox with oversized ears',
        'price': 195,
        'image_url': 'assets/pets/pets/real/fennec.png',
        'category_id': 3,
        'rarity': 'uncommon',
        'tags': ['tiny', 'ears', 'desert'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 10,
        'max_purchases': 1,
        'sort_order': 15,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Echo Bat',
        'description': 'A nocturnal bat that navigates by sound',
        'price': 210,
        'image_url': 'assets/pets/pets/real/honduran_bat.png',
        'category_id': 3,
        'rarity': 'rare',
        'tags': ['nocturnal', 'sound', 'night'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 11,
        'max_purchases': 1,
        'sort_order': 16,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Dash',
        'description': 'A speedy cheetah that runs like the wind',
        'price': 270,
        'image_url': 'assets/pets/pets/real/cheetah.png',
        'category_id': 3,
        'rarity': 'epic',
        'tags': ['speedy', 'wind', 'fast'],
        'is_available': true,
        'is_featured': true, // featured because it's limited time
        'requires_level': 15,
        'max_purchases': 1,
        'sort_order': 17,
        'metadata': {'limited_time': true},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      },
      {
        'name': 'Slither',
        'description': 'A mystical snake with ancient wisdom',
        'price': 240,
        'image_url': 'assets/pets/pets/real/snake.png',
        'category_id': 3,
        'rarity': 'rare',
        'tags': ['mystical', 'ancient', 'wisdom'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 14,
        'max_purchases': 1,
        'sort_order': 18,
        'metadata': {},
        'effect_type': null,
        'color_code': null,
        'unlocked_at': null
      }
    ];

    // Accessories (sample data - you can expand this)
    final accessories = [
      {
        'name': 'Crystal Crown',
        'description': 'A shimmering crown made of pure crystal',
        'price': 300,
        'image_url': 'assets/accessories/crystal_crown.png',
        'category_id': 1, // accessories category
        'rarity': 'legendary',
        'tags': ['crown', 'crystal', 'royal'],
        'is_available': true,
        'is_featured': true, // featured because it's limited time
        'requires_level': 20,
        'max_purchases': 1,
        'sort_order': 0,
        'metadata': {'limited_time': true},
        'effect_type': 'sparkle',
        'color_code': '#FFD700',
        'unlocked_at': null
      },
      {
        'name': 'Mystic Necklace',
        'description': 'A necklace that glows with inner magic',
        'price': 150,
        'image_url': 'assets/accessories/mystic_necklace.png',
        'category_id': 1,
        'rarity': 'rare',
        'tags': ['necklace', 'magic', 'glow'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 10,
        'max_purchases': 3,
        'sort_order': 1,
        'metadata': {},
        'effect_type': 'glow',
        'color_code': '#9370DB',
        'unlocked_at': null
      }
    ];

    // Tarot decks (sample data)
    final tarotDecks = [
      {
        'name': 'Celestial Deck',
        'description': 'A deck that connects you to the stars',
        'price': 250,
        'image_url': 'assets/tarot/celestial_deck.png',
        'category_id': 4, // tarot category
        'rarity': 'epic',
        'tags': ['celestial', 'stars', 'cosmic'],
        'is_available': true,
        'is_featured': false,
        'requires_level': 15,
        'max_purchases': 1,
        'sort_order': 0,
        'metadata': {},
        'effect_type': 'cosmic',
        'color_code': '#4B0082',
        'unlocked_at': null
      },
      {
        'name': 'Mystic Oracle',
        'description': 'An ancient deck with prophetic powers',
        'price': 400,
        'image_url': 'assets/tarot/mystic_oracle.png',
        'category_id': 4,
        'rarity': 'legendary',
        'tags': ['mystic', 'oracle', 'prophecy'],
        'is_available': true,
        'is_featured': true, // featured because it's limited time
        'requires_level': 25,
        'max_purchases': 1,
        'sort_order': 1,
        'metadata': {'limited_time': true},
        'effect_type': 'mystical',
        'color_code': '#800080',
        'unlocked_at': null
      }
    ];

    final allItems = [...pets, ...accessories, ...tarotDecks];
    
    // Get existing items
    print('Fetching existing shop items...');
    final getRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/shop_items?select=*'));
    getRequest.headers.set('apikey', supabaseKey);
    getRequest.headers.set('Authorization', 'Bearer $supabaseKey');
    
    final getResponse = await getRequest.close();
    final existingItemsJson = await getResponse.transform(utf8.decoder).join();
    final existingItems = jsonDecode(existingItemsJson) as List;
    
    print('Found ${existingItems.length} existing items');
    
    int created = 0;
    int updated = 0;
    
    for (final item in allItems) {
      try {
        // Check if item exists
        final existing = existingItems.where((e) => e['name'] == item['name']).firstOrNull;
        
        if (existing != null) {
          // Update existing item
          final updateRequest = await client.patchUrl(Uri.parse('$supabaseUrl/rest/v1/shop_items?id=eq.${existing['id']}'));
          updateRequest.headers.set('apikey', supabaseKey);
          updateRequest.headers.set('Authorization', 'Bearer $supabaseKey');
          updateRequest.headers.set('Content-Type', 'application/json');
          updateRequest.headers.set('Prefer', 'return=minimal');
          
          updateRequest.write(jsonEncode(item));
          final updateResponse = await updateRequest.close();
          
          if (updateResponse.statusCode == 204) {
            print('✓ Updated: ${item['name']}');
            updated++;
          } else {
            final errorBody = await updateResponse.transform(utf8.decoder).join();
            print('✗ Failed to update ${item['name']}: ${updateResponse.statusCode} - $errorBody');
          }
        } else {
          // Create new item
          final createRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/shop_items'));
          createRequest.headers.set('apikey', supabaseKey);
          createRequest.headers.set('Authorization', 'Bearer $supabaseKey');
          createRequest.headers.set('Content-Type', 'application/json');
          createRequest.headers.set('Prefer', 'return=minimal');
          
          createRequest.write(jsonEncode(item));
          final createResponse = await createRequest.close();
          
          if (createResponse.statusCode == 201) {
            print('✓ Created: ${item['name']}');
            created++;
          } else {
            final errorBody = await createResponse.transform(utf8.decoder).join();
            print('✗ Failed to create ${item['name']}: ${createResponse.statusCode} - $errorBody');
          }
        }
      } catch (e) {
        print('✗ Error processing ${item['name']}: $e');
      }
    }
    
    print('\nSync complete!');
    print('Created: $created items');
    print('Updated: $updated items');
    print('Total processed: ${allItems.length} items');
    
  } catch (e) {
    print('Error during sync: $e');
  } finally {
    client.close();
  }
}

extension FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
