import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin Support Dashboard - View and manage user support requests
class SupportDashboard extends StatefulWidget {
  const SupportDashboard({super.key});

  @override
  State<SupportDashboard> createState() => _SupportDashboardState();
}

class _SupportDashboardState extends State<SupportDashboard> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> supportRequests = [];
  bool isLoading = true;
  String selectedStatus = 'all';
  String selectedPriority = 'all';
  String selectedCategory = 'all';

  final statusOptions = ['all', 'open', 'in_progress', 'resolved', 'closed'];
  final priorityOptions = ['all', 'urgent', 'high', 'medium', 'low'];
  final categoryOptions = [
    'all',
    'Bug Report',
    'Feature Request',
    'General Question',
    'Account Issue',
    'Technical Problem',
    'Feedback'
  ];

  @override
  void initState() {
    super.initState();
    _loadSupportRequests();
  }

  Future<void> _loadSupportRequests() async {
    setState(() => isLoading = true);
    
    try {
      var query = supabase
          .from('support_requests')
          .select('*');

      // Apply filters
      if (selectedStatus != 'all') {
        query = query.eq('status', selectedStatus);
      }
      if (selectedPriority != 'all') {
        query = query.eq('priority', selectedPriority);
      }
      if (selectedCategory != 'all') {
        query = query.eq('category', selectedCategory);
      }

      final response = await query.order('created_at', ascending: false);
      
      setState(() {
        supportRequests = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load support requests: $e');
    }
  }

  Future<void> _updateRequestStatus(String requestId, String newStatus) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newStatus == 'resolved' || newStatus == 'closed') {
        updates['resolved_at'] = DateTime.now().toIso8601String();
      }

      await supabase
          .from('support_requests')
          .update(updates)
          .eq('id', requestId);

      await _loadSupportRequests();
      _showSuccessSnackBar('Status updated successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to update status: $e');
    }
  }

  Future<void> _addAdminResponse(String requestId, String currentResponse) async {
    final controller = TextEditingController(text: currentResponse);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Response'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your response to the user...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          maxLength: 1000,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await supabase
            .from('support_requests')
            .update({
              'admin_response': result,
              'admin_user_id': supabase.auth.currentUser?.id,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', requestId);

        await _loadSupportRequests();
        _showSuccessSnackBar('Response saved successfully!');
      } catch (e) {
        _showErrorSnackBar('Failed to save response: $e');
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.yellow.shade700;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return Colors.blue;
      case 'in_progress': return Colors.orange;
      case 'resolved': return Colors.green;
      case 'closed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Dashboard'),
        backgroundColor: Colors.blue.shade600,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSupportRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    hint: const Text('Status'),
                    isExpanded: true,
                    items: statusOptions.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.replaceAll('_', ' ').toUpperCase()),
                    )).toList(),
                    onChanged: (value) {
                      setState(() => selectedStatus = value!);
                      _loadSupportRequests();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedPriority,
                    hint: const Text('Priority'),
                    isExpanded: true,
                    items: priorityOptions.map((priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority.toUpperCase()),
                    )).toList(),
                    onChanged: (value) {
                      setState(() => selectedPriority = value!);
                      _loadSupportRequests();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    hint: const Text('Category'),
                    isExpanded: true,
                    items: categoryOptions.map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category == 'all' ? 'ALL' : category),
                    )).toList(),
                    onChanged: (value) {
                      setState(() => selectedCategory = value!);
                      _loadSupportRequests();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Total', supportRequests.length.toString(), Colors.blue),
                _buildStatCard('Open', 
                  supportRequests.where((r) => r['status'] == 'open').length.toString(), 
                  Colors.orange),
                _buildStatCard('Resolved', 
                  supportRequests.where((r) => r['status'] == 'resolved').length.toString(), 
                  Colors.green),
              ],
            ),
          ),

          // Requests List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : supportRequests.isEmpty
                    ? const Center(
                        child: Text(
                          'No support requests found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: supportRequests.length,
                        itemBuilder: (context, index) {
                          final request = supportRequests[index];
                          return _buildRequestCard(request);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final createdAt = DateTime.parse(request['created_at']);
    final timeAgo = _getTimeAgo(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(request['priority']),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    request['priority'].toString().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request['status']),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    request['status'].toString().replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // User Info
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  request['username'] ?? 'Unknown User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (request['email'] != null && request['email'].toString().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${request['email']})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Category
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  request['category'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Subject
            Text(
              request['subject'] ?? 'No Subject',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              request['description'] ?? 'No description provided',
              style: const TextStyle(fontSize: 14),
            ),

            // Admin Response
            if (request['admin_response'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Response:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(request['admin_response']),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                DropdownButton<String>(
                  value: request['status'],
                  items: ['open', 'in_progress', 'resolved', 'closed']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.replaceAll('_', ' ').toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      _updateRequestStatus(request['id'], newStatus);
                    }
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _addAdminResponse(
                    request['id'],
                    request['admin_response'] ?? '',
                  ),
                  icon: const Icon(Icons.reply, size: 16),
                  label: Text(request['admin_response'] != null ? 'Edit Response' : 'Add Response'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
