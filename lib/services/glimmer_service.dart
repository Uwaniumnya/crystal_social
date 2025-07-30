import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Service for managing Glimmer Wall posts and interactions
class GlimmerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all posts with user information and like status
  Future<List<Map<String, dynamic>>> getPosts({
    String? category,
    String? searchQuery,
    String? currentUserId,
  }) async {
    try {
      // Try to use the database function first
      if (currentUserId != null) {
        final response = await _supabase.rpc('get_glimmer_posts_for_user', params: {
          'current_user_id': currentUserId,
        });
        
        var posts = List<Map<String, dynamic>>.from(response);
        
        // Apply filters
        if (category != null && category != 'All') {
          posts = posts.where((post) => post['category'] == category).toList();
        }
        
        if (searchQuery != null && searchQuery.isNotEmpty) {
          posts = posts.where((post) {
            final title = post['title']?.toString().toLowerCase() ?? '';
            final description = post['description']?.toString().toLowerCase() ?? '';
            final tags = List<String>.from(post['tags'] ?? []);
            final query = searchQuery.toLowerCase();
            
            return title.contains(query) ||
                   description.contains(query) ||
                   tags.any((tag) => tag.toLowerCase().contains(query));
          }).toList();
        }
        
        return posts;
      } else {
        // Fallback to simple query
        var query = _supabase.from('glimmer_posts_with_stats').select('*');
        
        if (category != null && category != 'All') {
          query = query.eq('category', category);
        }
        
        final response = await query.order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      print('Error fetching posts: $e');
      rethrow;
    }
  }

  /// Upload a new glimmer post
  Future<String> uploadPost({
    required String title,
    required String description,
    required File imageFile,
    required String category,
    required String userId,
    required List<String> tags,
  }) async {
    try {
      // Create a unique filename for the image
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload image to Supabase Storage
      await _supabase.storage
          .from('glimmer-images')
          .upload(fileName, imageFile);
      
      // Get the public URL for the uploaded image
      final imageUrl = _supabase.storage
          .from('glimmer-images')
          .getPublicUrl(fileName);

      // Insert the post into the database
      final response = await _supabase.from('glimmer_posts').insert({
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'image_path': fileName,
        'category': category,
        'user_id': userId,
        'tags': tags,
      }).select().single();

      return response['id'];
    } catch (e) {
      print('Error uploading post: $e');
      rethrow;
    }
  }

  /// Toggle like status for a post
  Future<bool> toggleLike({
    required String postId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    try {
      if (currentlyLiked) {
        await _supabase
            .from('glimmer_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
        return false;
      } else {
        await _supabase
            .from('glimmer_likes')
            .insert({
          'post_id': postId,
          'user_id': userId,
        });
        return true;
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  /// Add a comment to a post
  Future<String> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      final response = await _supabase.from('glimmer_comments').insert({
        'post_id': postId,
        'user_id': userId,
        'content': content,
      }).select().single();

      return response['id'];
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  /// Get comments for a post
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('glimmer_comments')
          .select('''
            *,
            users:user_id (
              email,
              raw_user_meta_data
            )
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching comments: $e');
      rethrow;
    }
  }

  /// Delete a post (only by the owner)
  Future<void> deletePost({
    required String postId,
    required String userId,
    String? imagePath,
  }) async {
    try {
      // Delete the post from database (this will cascade delete likes and comments)
      await _supabase
          .from('glimmer_posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', userId);

      // Delete the image from storage if provided
      if (imagePath != null) {
        await _supabase.storage
            .from('glimmer-images')
            .remove([imagePath]);
      }
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }
}
