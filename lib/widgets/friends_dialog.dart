import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/challenge_state.dart';
import '../models/notification_state.dart';

class FriendsDialog extends StatefulWidget {
  const FriendsDialog({super.key});

  @override
  State<FriendsDialog> createState() => _FriendsDialogState();
}

class _FriendsDialogState extends State<FriendsDialog> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSending = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChallengeState>().syncFromSupabase();
      }
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest(ChallengeState state) async {
    final input = _idController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await state.sendFriendRequest(input);
      _idController.clear();
      setState(() {
        _successMessage = 'Friend request sent to $input!';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showEditNameDialog(BuildContext context, ChallengeState state) {
    _nameController.text = state.currentUser.displayName;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              state.updateDisplayName(_nameController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChallengeState>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.people, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Text(
                      'Friends & Public ID',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // User Public ID Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.currentUser.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Text(
                            'Your Sharable Public ID:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Edit Name',
                        onPressed: () => _showEditNameDialog(context, state),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SelectableText(
                          state.currentUser.publicId,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.blueGrey,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          tooltip: 'Copy ID',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: state.currentUser.publicId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Public ID copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Send Friend Request Input
            const Text(
              'Add Friend by Public ID',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. TM-A8F3K9',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSending ? null : () => _sendRequest(state),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: _isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Add'),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 4),
              Text(_successMessage!, style: const TextStyle(color: Colors.green, fontSize: 12)),
            ],

            const SizedBox(height: 16),

            // Tabbed / List View for Incoming Requests & Friends List
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: Colors.blueGrey,
                      indicatorColor: Colors.blueGrey,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Friends'),
                              if (state.friends.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.blueGrey.withValues(alpha: 0.2),
                                  child: Text(
                                    '${state.friends.length}',
                                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Requests'),
                              if (state.incomingRequests.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.orange,
                                  child: Text(
                                    '${state.incomingRequests.length}',
                                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Friends List
                          state.friends.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.people_outline, size: 40, color: Colors.grey),
                                      const SizedBox(height: 8),
                                      const Text('No friends added yet.', style: TextStyle(color: Colors.grey)),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => state.addMockIncomingChallenge(notificationState: context.read<NotificationState>()),
                                        icon: const Icon(Icons.flash_on, size: 16),
                                        label: const Text('Add Demo Friend & Challenge'),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: state.friends.length,
                                  separatorBuilder: (_, _) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final friend = state.friends[index];
                                    return ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.blueGrey,
                                        child: Icon(Icons.person, color: Colors.white),
                                      ),
                                      title: Text(friend.friendName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(friend.friendPublicId),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        tooltip: 'Remove Friend',
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Remove Friend?'),
                                              content: Text('Are you sure you want to remove ${friend.friendName}?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    state.removeFriend(friend.friendUserId);
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),

                          // Tab 2: Incoming Requests
                          state.incomingRequests.isEmpty
                              ? const Center(
                                  child: Text('No pending friend requests.', style: TextStyle(color: Colors.grey)),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: state.incomingRequests.length,
                                  separatorBuilder: (_, _) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final req = state.incomingRequests[index];
                                    return ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.orange,
                                        child: Icon(Icons.person_add, color: Colors.white),
                                      ),
                                      title: Text(req.fromUserName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(req.fromPublicId),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            tooltip: 'Decline',
                                            onPressed: () => state.rejectFriendRequest(req),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.check_circle, color: Colors.green),
                                            tooltip: 'Accept',
                                            onPressed: () => state.acceptFriendRequest(req, notificationState: context.read<NotificationState>()),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ],
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
  }
}
