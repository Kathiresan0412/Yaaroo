import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/api_client.dart';
import '../../../main.dart' show YaaroColors, YaaroScope;

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    required this.matchId,
    required this.matchName,
    this.matchPhotoUrl,
    super.key,
  });

  final String matchId;
  final String matchName;
  final String? matchPhotoUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  String? _nextCursor;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isOnline = false;
  String? _notice;
  String _matchNameState = '';
  String? _matchPhotoState;

  io.Socket? _socket;
  String? _currentUserId;
  late ApiClient _apiClient;
  bool _showGifs = false;
  String? _selectedMessageId;

  // Voice note simulator states
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  // Active audio playback simulations
  final Map<String, double> _audioPlaybackPosition = {}; // messageId -> progress (0.0 to 1.0)
  final Map<String, bool> _audioPlayingState = {}; // messageId -> isPlaying
  final Map<String, Timer?> _audioPlaybackTimers = {}; // messageId -> timer

  final List<String> _gifChoices = [
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExcnV6dW1zZHY3dW5kdzYzbjdiaWl1MHN4bGlna3F0d2U5M2drYm90NSZlcD12MV9naWZzX3NlYXJjaCZjdD1n/3oriO0OEd9QIDdllqo/giphy.gif',
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExaDd0N2s0MmI5YnUydnVvOXM0cmFucnF3bmxwbm93M2kwY3N3bTliZCZlcD12MV9naWZzX3NlYXJjaCZjdD1n/l0MYt5jPR6QX5pnqM/giphy.gif',
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHRqeTQ1a2Y3ZXl4d21ybXlpc3ZtN2xyYzZzN2VucXRpZWI3dThiaSZlcD12MV9naWZzX3NlYXJjaCZjdD1n/26BRv0ThflsHCqDrG/giphy.gif',
  ];

  final List<String> _reactionChoices = ["❤️", "😂", "🔥", "👏", "✨"];

  @override
  void initState() {
    super.initState();
    _matchNameState = widget.matchName;
    _matchPhotoState = widget.matchPhotoUrl;
    _scrollController.addListener(_onScroll);
    Future.delayed(Duration.zero, _initializeChat);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _recordTimer?.cancel();
    for (var timer in _audioPlaybackTimers.values) {
      timer?.cancel();
    }
    _leaveAndDisconnectSocket();
    super.dispose();
  }

  void _onScroll() {
    // Scroll near top to fetch pagination cursor
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      if (_nextCursor != null && !_isLoadingMore) {
        _loadMoreMessages();
      }
    }
  }

  void _leaveAndDisconnectSocket() {
    if (_socket != null) {
      try {
        _socket!.emit('leave_match', {'matchId': widget.matchId});
        _socket!.disconnect();
      } catch (_) {}
      _socket = null;
    }
  }

  Future<void> _initializeChat() async {
    _apiClient = YaaroScope.of(context);
    _currentUserId = _apiClient.user?.id;

    // Load matches to extract updated details if available
    _fetchMatchDetails();

    // REST initial pagination load (limit 30)
    await _loadMessages(null);

    // Socket.IO configuration
    _setupSocket();
  }

  Future<void> _fetchMatchDetails() async {
    try {
      final list = await _apiClient.matches();
      final currentMatch = list.firstWhere((item) => item.id == widget.matchId);
      setState(() {
        _matchNameState = currentMatch.name;
        _matchPhotoState = currentMatch.photoUrl;
      });
    } catch (_) {}
  }

  Future<void> _loadMessages(String? cursor) async {
    if (cursor == null) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final payload = await _apiClient.getMessages(widget.matchId, cursor: cursor);
      final rawMessages = payload['messages'] as List? ?? [];
      final incoming = rawMessages
          .whereType<Map<String, dynamic>>()
          .map((json) => ChatMessage.fromJson(json, _currentUserId ?? ''))
          .toList();

      _mergeAndSortMessages(incoming);
      _nextCursor = payload['nextCursor']?.toString();

      if (cursor == null) {
        // Trigger auto read ticks for incoming matched unread messages
        _markUnreadAsRead();
      }
    } catch (e) {
      setState(() {
        _notice = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _mergeAndSortMessages(List<ChatMessage> incoming) {
    final map = <String, ChatMessage>{};
    for (var m in _messages) {
      map[m.id] = m;
    }
    for (var m in incoming) {
      map[m.id] = m;
    }

    final sorted = map.values.toList()
      ..sort((a, b) => DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));

    setState(() {
      _messages.clear();
      _messages.addAll(sorted);
    });
  }

  Future<void> _loadMoreMessages() async {
    if (_nextCursor == null || _isLoadingMore) return;
    await _loadMessages(_nextCursor);
  }

  void _markUnreadAsRead() {
    for (var m in _messages) {
      if (!m.isMine && !m.isRead) {
        _apiClient.markMessageRead(m.id).catchError((_) {});
        if (_socket != null && _socket!.connected) {
          _socket!.emit('mark_read', {'matchId': widget.matchId, 'messageId': m.id});
        }
      }
    }
  }

  void _setupSocket() {
    final token = _apiClient.accessToken;
    if (token == null) return;

    // Use backend URL or process environment
    const String socketUrl = String.fromEnvironment(
      'YAARO0_SOCKET_URL',
      defaultValue: 'https://yaaro-backend.vercel.app',
    );

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      setState(() => _notice = null);
      _socket!.emitWithAck(
        'join_match',
        {'matchId': widget.matchId},
        ack: (ackData) {
          if (ackData is Map) {
            final success = ackData['success'] == true;
            if (success) {
              setState(() {
                _isOnline = ackData['isOnline'] == true;
              });
            }
          }
        },
      );
    });

    _socket!.onConnectError((_) {
      setState(() => _notice = 'Live chat is reconnecting.');
    });

    _socket!.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        final msg = ChatMessage.fromJson(data, _currentUserId ?? '');
        if (msg.matchId == widget.matchId) {
          _mergeAndSortMessages([msg]);
          // Mark immediately read
          _socket!.emit('mark_read', {'matchId': widget.matchId, 'messageId': msg.id});
          _apiClient.markMessageRead(msg.id).catchError((_) {});
        }
      }
    });

    _socket!.on('message_read', (data) {
      if (data is Map) {
        final evMatchId = data['matchId']?.toString();
        final readAt = data['readAt']?.toString();
        if (evMatchId == widget.matchId) {
          setState(() {
            for (var i = 0; i < _messages.length; i++) {
              if (_messages[i].isMine) {
                _messages[i] = _messages[i].copyWith(isRead: true, readAt: readAt);
              }
            }
          });
        }
      }
    });

    _socket!.on('message_reaction', (data) {
      if (data is Map && data['message'] is Map<String, dynamic>) {
        final updatedJson = data['message'] as Map<String, dynamic>;
        final updatedMsg = ChatMessage.fromJson(updatedJson, _currentUserId ?? '');
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == updatedMsg.id);
          if (idx != -1) {
            _messages[idx] = updatedMsg;
          }
        });
      }
    });

    _socket!.on('presence_update', (data) {
      if (data is Map) {
        final online = data['isOnline'] == true;
        setState(() {
          _isOnline = online;
        });
      }
    });

    _socket!.connect();
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    // Check socket connectivity
    if (_socket != null && _socket!.connected) {
      _socket!.emitWithAck(
        'send_message',
        {'matchId': widget.matchId, 'content': text, 'type': 'text'},
        ack: (ack) {
          if (ack is Map && ack['success'] == true) {
            // Socket message is sent, wait for 'new_message' socket event or load from REST
          } else {
            setState(() {
              _notice = 'WebSocket delivery failure, trying REST...';
            });
            _fallbackSendTextREST(text);
          }
        },
      );
    } else {
      await _fallbackSendTextREST(text);
    }
  }

  Future<void> _fallbackSendTextREST(String text) async {
    try {
      final res = await _apiClient.sendMessage(widget.matchId, text, 'text');
      if (res['success'] == true && res['message'] is Map<String, dynamic>) {
        final newMsg = ChatMessage.fromJson(res['message'], _currentUserId ?? '');
        _mergeAndSortMessages([newMsg]);
      }
    } catch (e) {
      setState(() => _notice = e.toString());
    }
  }

  Future<void> _sendPhoto() async {
    setState(() {
      _notice = 'Photo sharing from device is not available in this build yet.';
    });
  }

  Future<void> _sendGif(String url) async {
    setState(() {
      _showGifs = false;
      _isLoading = true;
    });

    try {
      final res = await _apiClient.sendMessage(widget.matchId, '', 'gif', mediaUrl: url);
      if (res['success'] == true && res['message'] is Map<String, dynamic>) {
        final newMsg = ChatMessage.fromJson(res['message'], _currentUserId ?? '');
        _mergeAndSortMessages([newMsg]);
      }
    } catch (e) {
      setState(() => _notice = 'GIF transmission failure: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleRecording() {
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
      _notice = 'Voice messages are not available in this build yet.';
    });
  }

  Future<void> _react(String messageId, String emoji) async {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('react_message', {'messageId': messageId, 'emoji': emoji});
    } else {
      try {
        await _apiClient.reactToMessage(messageId, emoji);
        // Force reloading or manual local merge
        _loadMessages(null);
      } catch (_) {}
    }
    setState(() {
      _selectedMessageId = null;
    });
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _apiClient.deleteMessage(messageId);
      setState(() {
        for (var i = 0; i < _messages.length; i++) {
          if (_messages[i].id == messageId) {
            _messages[i] = _messages[i].copyWith(isDeleted: true, content: null, mediaUrl: null);
          }
        }
      });
    } catch (e) {
      setState(() => _notice = 'Failed to delete message.');
    }
    setState(() {
      _selectedMessageId = null;
    });
  }

  Future<void> _reportMessage(String messageId) async {
    try {
      await _apiClient.reportMessage(messageId);
      setState(() {
        _notice = 'Safety report filed successfully.';
      });
    } catch (e) {
      setState(() => _notice = 'Failed to report message.');
    }
    setState(() {
      _selectedMessageId = null;
    });
  }

  // Audio Playback Simulation Engine
  void _toggleAudioPlayback(ChatMessage message) {
    final msgId = message.id;
    final isPlaying = _audioPlayingState[msgId] ?? false;

    if (isPlaying) {
      setState(() {
        _audioPlayingState[msgId] = false;
        _audioPlaybackTimers[msgId]?.cancel();
      });
    } else {
      setState(() {
        _audioPlayingState[msgId] = true;
      });

      final totalDuration = message.durationSeconds ?? 8;
      const tick = Duration(milliseconds: 100);
      final step = 0.1 / totalDuration;

      _audioPlaybackTimers[msgId] = Timer.periodic(tick, (timer) {
        final currentPos = _audioPlaybackPosition[msgId] ?? 0.0;
        if (currentPos >= 1.0) {
          timer.cancel();
          setState(() {
            _audioPlayingState[msgId] = false;
            _audioPlaybackPosition[msgId] = 0.0;
          });
        } else {
          setState(() {
            _audioPlaybackPosition[msgId] = currentPos + step;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMsg = _selectedMessageId != null
        ? _messages.firstWhere((m) => m.id == _selectedMessageId)
        : null;

    final lastMineRead = _messages.firstWhere(
      (m) => m.isMine && m.isRead,
      orElse: () => ChatMessage(
        id: '',
        matchId: '',
        senderId: '',
        type: 'system',
        reactions: [],
        isMine: false,
        isRead: false,
        isDeleted: false,
        createdAt: '',
      ),
    );

    return Scaffold(
      backgroundColor: YaaroColors.black,
      appBar: AppBar(
        backgroundColor: YaaroColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: _matchPhotoState != null
                      ? NetworkImage(_matchPhotoState!)
                      : null,
                  backgroundColor: YaaroColors.surfaceAlt,
                  child: _matchPhotoState == null
                      ? const Icon(Icons.person, color: Colors.white54)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _isOnline ? YaaroColors.teal : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: YaaroColors.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _matchNameState,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  _isOnline ? 'Online now' : 'Reconnecting when active',
                  style: TextStyle(
                    color: _isOnline ? YaaroColors.teal : Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 1,
      ),
      body: Column(
        children: [
          if (_notice != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: YaaroColors.saffron.withOpacity(0.18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _notice!,
                      style: const TextStyle(color: YaaroColors.saffron, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: YaaroColors.saffron, size: 16),
                    onPressed: () => setState(() => _notice = null),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: YaaroColors.rose))
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Say hello to start the chat.',
                          style: TextStyle(color: Colors.white30, fontSize: 15),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final showSeen = lastMineRead.id.isNotEmpty && message.id == lastMineRead.id;
                          return Column(
                            crossAxisAlignment: message.isMine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              _buildMessageBubble(message),
                              if (showSeen && message.readAt != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, right: 8, bottom: 8),
                                  child: Text(
                                    'Seen ${DateFormat('jm').format(DateTime.parse(message.readAt!))}',
                                    style: const TextStyle(fontSize: 10, color: Colors.white24),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
          ),
          if (selectedMsg != null) _buildReactionPanel(selectedMsg),
          if (_showGifs) _buildGifPicker(),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isMine = message.isMine;
    final parsedTime = DateTime.parse(message.createdAt);
    final timeStr = DateFormat('jm').format(parsedTime);

    return InkWell(
      onLongPress: () {
        setState(() {
          _selectedMessageId = message.id;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isDeleted
              ? Colors.white.withOpacity(0.04)
              : isMine
                  ? YaaroColors.rose
                  : YaaroColors.surfaceAlt,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: Border.all(
            color: message.isDeleted ? Colors.white12 : Colors.transparent,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.isDeleted)
              const Text(
                'Message deleted',
                style: TextStyle(
                  color: Colors.white30,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              )
            else if (message.type == 'photo' || message.type == 'image' || message.type == 'gif')
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  message.mediaUrl ?? '',
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator(color: Colors.white30)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.white10,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white38),
                    ),
                  ),
                  fit: BoxFit.cover,
                ),
              )
            else if (message.type == 'voice')
              _buildVoicePlayer(message)
            else
              Text(
                message.content ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
                if (!message.isDeleted) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.sentiment_satisfied, size: 12, color: Colors.white38),
                ],
              ],
            ),
            if (message.reactions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  message.reactions.map((r) => r.emoji).join(' '),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoicePlayer(ChatMessage message) {
    final msgId = message.id;
    final isPlaying = _audioPlayingState[msgId] ?? false;
    final progress = _audioPlaybackPosition[msgId] ?? 0.0;
    final duration = message.durationSeconds ?? 8;
    final elapsed = (progress * duration).round();

    return Row(
      children: [
        IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () => _toggleAudioPlayback(message),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: progress,
                color: Colors.white,
                backgroundColor: Colors.white30,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0:${elapsed.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                  Text(
                    '0:${duration.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReactionPanel(ChatMessage message) {
    return Container(
      color: YaaroColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _reactionChoices.map((emoji) {
              return InkWell(
                onTap: () => _react(message.id, emoji),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              );
            }).toList(),
          ),
          const Divider(color: YaaroColors.line),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (message.isMine)
                TextButton.icon(
                  onPressed: () => _deleteMessage(message.id),
                  icon: const Icon(Icons.delete, color: YaaroColors.rose),
                  label: const Text('Delete Message', style: TextStyle(color: YaaroColors.rose)),
                ),
              TextButton.icon(
                onPressed: () => _reportMessage(message.id),
                icon: const Icon(Icons.flag, color: YaaroColors.saffron),
                label: const Text('Report Safety', style: TextStyle(color: YaaroColors.saffron)),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedMessageId = null),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGifPicker() {
    return Container(
      height: 120,
      color: YaaroColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        itemCount: _gifChoices.length,
        itemBuilder: (context, index) {
          final url = _gifChoices[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              onTap: () => _sendGif(url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(url, width: 140, fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
      decoration: const BoxDecoration(
        color: YaaroColors.surface,
        border: Border(top: BorderSide(color: YaaroColors.line)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: YaaroColors.muted),
            onPressed: _sendPhoto,
          ),
          IconButton(
            icon: Icon(Icons.gif, color: _showGifs ? YaaroColors.rose : YaaroColors.muted),
            onPressed: () {
              setState(() {
                _showGifs = !_showGifs;
              });
            },
          ),
          InkWell(
            onTap: _toggleRecording,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isRecording ? YaaroColors.rose.withOpacity(0.24) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mic,
                color: _isRecording ? YaaroColors.rose : YaaroColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _isRecording
                ? Row(
                    children: [
                      const Icon(Icons.fiber_manual_record, color: YaaroColors.rose, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Recording: 0:${_recordSeconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: YaaroColors.rose, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      const Text(
                        'Tap Mic to Send',
                        style: TextStyle(color: Colors.white24, fontSize: 12),
                      ),
                    ],
                  )
                : TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendText(),
                  ),
          ),
          if (!_isRecording)
            IconButton(
              icon: const Icon(Icons.send, color: YaaroColors.rose),
              onPressed: _sendText,
            ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String matchId;
  final String senderId;
  final String type; // 'text' | 'photo' | 'gif' | 'voice' | 'image' | 'system'
  final String? content;
  final String? mediaUrl;
  final int? durationSeconds;
  final List<MessageReaction> reactions;
  final bool isMine;
  final bool isRead;
  final String? readAt;
  final bool isDeleted;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.durationSeconds,
    required this.reactions,
    required this.isMine,
    required this.isRead,
    this.readAt,
    required this.isDeleted,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    final rawReactions = json['reactions'] as List? ?? [];
    final parsedReactions = rawReactions
        .whereType<Map<String, dynamic>>()
        .map(MessageReaction.fromJson)
        .toList();

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      matchId: json['matchId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      content: json['content']?.toString(),
      mediaUrl: json['mediaUrl']?.toString() ?? json['gifUrl']?.toString(),
      durationSeconds: int.tryParse(json['durationSeconds']?.toString() ?? ''),
      reactions: parsedReactions,
      isMine: (json['senderId']?.toString() == currentUserId) || json['isMine'] == true,
      isRead: json['isRead'] == true,
      readAt: json['readAt']?.toString(),
      isDeleted: json['isDeleted'] == true,
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  ChatMessage copyWith({
    bool? isRead,
    String? readAt,
    bool? isDeleted,
    String? content,
    String? mediaUrl,
  }) {
    return ChatMessage(
      id: id,
      matchId: matchId,
      senderId: senderId,
      type: type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      durationSeconds: durationSeconds,
      reactions: reactions,
      isMine: isMine,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
    );
  }
}

class MessageReaction {
  final String userId;
  final String emoji;

  MessageReaction({required this.userId, required this.emoji});

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      userId: json['userId']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '',
    );
  }
}
