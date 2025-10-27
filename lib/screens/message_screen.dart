import 'package:flutter/material.dart';
import '../models/message.dart';
import '../client/rest_client.dart';

class MessageScreen extends StatefulWidget {
  final RestClient client;
  final int userId;

  const MessageScreen({Key? key, required this.client, required this.userId})
    : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final messages = await widget.client.fetchMessages(userId: widget.userId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Mark unread messages as read
      for (final msg in messages.where((m) => !m.isRead)) {
        await widget.client.markMessageAsRead(msg.id!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading messages: $e')));
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    try {
      final message = Message(
        senderId: widget.userId,
        receiverId: 1, // TODO: Replace with actual recipient ID
        content: content,
        timestamp: DateTime.now(),
      );

      final sent = await widget.client.sendMessage(message);
      setState(() {
        _messages = [..._messages, sent];
      });

      // Scroll to bottom after message is sent
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMessages),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isSentByMe = message.senderId == widget.userId;

                        return Align(
                          alignment:
                              isSentByMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSentByMe
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                        context,
                                      ).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  isSentByMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.content,
                                  style: TextStyle(
                                    color:
                                        isSentByMe
                                            ? Colors.white
                                            : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message.timestamp
                                      .toLocal()
                                      .toString()
                                      .substring(11, 16),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isSentByMe
                                            ? Colors.white70
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
