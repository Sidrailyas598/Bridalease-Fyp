import 'package:flutter/material.dart';
import 'package:pubnub/pubnub.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

// Supabase instance (Make sure this is initialized in main.dart)
final supabase = Supabase.instance.client;

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late PubNub _pubnub;
  late Subscription _subscription; // ✅ Subscription variable
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late String _channel;
  bool _isInitialized = false;
  bool _otherUserOnline = false;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Unique channel for two users
    List<String> ids = [widget.currentUserId, widget.otherUserId];
    ids.sort();
    _channel = 'chat_${ids[0]}_${ids[1]}';
    _initializePubNub();
  }

  Future<void> _initializePubNub() async {
    try {
      await dotenv.load(fileName: ".env");

      // ✅ FIX: Keyset and UserId for 4.3.4
      _pubnub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: dotenv.env['PUBNUB_SUBSCRIBE_KEY']!,
          publishKey: dotenv.env['PUBNUB_PUBLISH_KEY']!,
          userId: UserId(widget.currentUserId), // 4.3.4 uses UserId
        ),
      );

      // ✅ FIX: Create subscription first
      _subscription = _pubnub.subscribe(channels: {_channel});

      // ✅ FIX: Listen to messages from the subscription object
      _subscription.messages.listen((message) {
        if (mounted) {
          setState(() {
            _messages.add({
              'text': message.content['text'] ?? '',
              'sender': message.content['sender'] ?? '',
              'time': DateTime.now(),
              'type': message.content['type'] ?? 'text',
              'imageUrl': message.content['imageUrl'],
            });
          });
          _scrollToBottom();
        }
      });

      // ✅ FIX: Presence listener via subscription
      _subscription.presence.listen((presence) {
        if (mounted) {
          setState(() {
            _otherUserOnline = presence.occupancy > 1;
          });
        }
      });

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('❌ PubNub error: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messagePayload = {
      'text': _messageController.text.trim(),
      'sender': widget.currentUserId,
      'type': 'text',
      'time': DateTime.now().toIso8601String(),
    };

    try {
      // ✅ Simple publish
      await _pubnub.publish(_channel, messagePayload);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint('❌ Send error: $e');
    }
  }

  Future<void> _sendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 70,
      );

      if (image != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'chats/${widget.currentUserId}/$fileName';
        
        final fileBytes = await image.readAsBytes();
        await supabase.storage.from('chat-images').uploadBinary(path, fileBytes);
        
        final imageUrl = supabase.storage.from('chat-images').getPublicUrl(path);

        final messagePayload = {
          'text': '📷 Image',
          'sender': widget.currentUserId,
          'type': 'image',
          'imageUrl': imageUrl,
          'time': DateTime.now().toIso8601String(),
        };
        
        await _pubnub.publish(_channel, messagePayload);
      }
    } catch (e) {
      debugPrint('❌ Image error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF660033),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(widget.otherUserName[0].toUpperCase()),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName, style: const TextStyle(fontSize: 16)),
                Text(
                  _otherUserOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12, 
                    color: _otherUserOnline ? Colors.greenAccent : Colors.white70
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender'] == widget.currentUserId;
                      
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF660033) : Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (msg['type'] == 'image')
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(msg['imageUrl']),
                                )
                              else
                                Text(
                                  msg['text'],
                                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: Color(0xFF660033)),
            onPressed: _sendImage,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            backgroundColor: const Color(0xFF660033),
            onPressed: _sendMessage,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // ✅ Properly unsubscribe
    _pubnub.unsubscribeAll(); 
    super.dispose();
  }
}