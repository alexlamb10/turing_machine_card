import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_state.dart';
import '../models/friend.dart';
import 'friends_dialog.dart';

class SendChallengeDialog extends StatefulWidget {
  final String puzzleHash;
  final bool won;
  final bool beatMachine;
  final int clues;
  final int rounds;

  const SendChallengeDialog({
    super.key,
    required this.puzzleHash,
    required this.won,
    required this.beatMachine,
    required this.clues,
    required this.rounds,
  });

  @override
  State<SendChallengeDialog> createState() => _SendChallengeDialogState();
}

class _SendChallengeDialogState extends State<SendChallengeDialog> {
  final Set<String> _selectedFriendIds = {};
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChallengeState>();
    final friends = state.friends;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Challenge Friends',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Puzzle Hash: ${widget.puzzleHash}',
                        style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            if (friends.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'You have no friends on your list yet.',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (ctx) => const FriendsDialog(),
                        );
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Friends'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Friends (${_selectedFriendIds.length}/${friends.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedFriendIds.length == friends.length) {
                          _selectedFriendIds.clear();
                        } else {
                          _selectedFriendIds.addAll(friends.map((f) => f.friendUserId));
                        }
                      });
                    },
                    child: Text(
                      _selectedFriendIds.length == friends.length ? 'Deselect All' : 'Select All',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    final isSelected = _selectedFriendIds.contains(friend.friendUserId);

                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(friend.friendName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(friend.friendPublicId),
                      secondary: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blueGrey,
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedFriendIds.add(friend.friendUserId);
                          } else {
                            _selectedFriendIds.remove(friend.friendUserId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: (_selectedFriendIds.isEmpty || _isSending)
                    ? null
                    : () async {
                        setState(() => _isSending = true);
                        final selectedFriends =
                            friends.where((f) => _selectedFriendIds.contains(friendUserId(f))).toList();

                        await state.sendChallenge(
                          puzzleHash: widget.puzzleHash,
                          targetFriends: selectedFriends,
                          won: widget.won,
                          beatMachine: widget.beatMachine,
                          clues: widget.clues,
                          rounds: widget.rounds,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Challenge sent to ${selectedFriends.length} friend${selectedFriends.length > 1 ? 's' : ''}!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.send),
                label: _isSending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Send Challenge (${_selectedFriendIds.length})', style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String friendUserId(Friendship f) => f.friendUserId;
}
