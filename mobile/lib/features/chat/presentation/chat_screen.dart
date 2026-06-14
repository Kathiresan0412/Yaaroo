import 'dart:async';
import 'dart:io' as dart_io;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/api_client.dart';
import '../../../core/services/chat_repository.dart';
import '../../../main.dart'
    show MatchItem, YaaroColors, YaaroScope, isBackendNumericId, socketBaseUrl;
import 'zego_call_screen.dart';

// ---------------------------------------------------------------------------
// Theme helpers
// ---------------------------------------------------------------------------
Color _scaffoldBg(BuildContext context) => YaaroColors.isDarkFor(context)
    ? YaaroColors.black
    : const Color(0xFFF2F3F7);
Color _surfaceColor(BuildContext context) =>
    YaaroColors.isDarkFor(context) ? YaaroColors.surface : Colors.white;
Color _surfaceAltColor(BuildContext context) => YaaroColors.isDarkFor(context)
    ? YaaroColors.surfaceAlt
    : const Color(0xFFEBECF0);
Color _inputHintColor(BuildContext context) =>
    YaaroColors.isDarkFor(context) ? Colors.white38 : Colors.black38;
Color _timestampColor(BuildContext context) =>
    YaaroColors.isDarkFor(context) ? Colors.white38 : Colors.black38;
Color _seenColor(BuildContext context) =>
    YaaroColors.isDarkFor(context) ? Colors.white24 : Colors.black26;
Color _bubbleTextColor(BuildContext context, {required bool isMine}) {
  if (isMine) return Colors.white;
  return YaaroColors.isDarkFor(context)
      ? Colors.white
      : const Color(0xFF111216);
}

Color _deletedBubbleBorder(BuildContext context) =>
    YaaroColors.isDarkFor(context) ? Colors.white12 : Colors.black12;
Color _deletedBubbleBg(BuildContext context) => YaaroColors.isDarkFor(context)
    ? Colors.white.withOpacity(0.04)
    : Colors.black.withOpacity(0.04);
Color _reactionBadgeBg(BuildContext context) => YaaroColors.isDarkFor(context)
    ? Colors.black26
    : Colors.black.withOpacity(0.06);

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
  bool _isUploading = false;
  bool _isLoadingMore = false;
  bool _isOnline = false;
  String? _notice;
  String _matchNameState = '';
  String? _matchPhotoState;
  String? _lastActiveAt;
  String?
      _realMatchId; // actual match ID from backend (may differ from widget.matchId)

  io.Socket? _socket;
  String? _currentUserId;
  String? _otherUserId;
  late ApiClient _apiClient;

  // attachment panel toggle
  bool _showAttachPanel = false;
  String? _selectedMessageId;

  // socket reconnect state
  bool _socketEverConnected = false;
  Timer? _reconnectTimer;

  // voice recording
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _recordingPath;

  // typing
  Timer? _typingStopTimer;
  bool _hasSentTypingStart = false;
  bool _isOtherTyping = false;

  // audio playback simulation
  final Map<String, double> _audioPlaybackPosition = {};
  final Map<String, bool> _audioPlayingState = {};
  final Map<String, Timer?> _audioPlaybackTimers = {};

  final List<String> _reactionChoices = ["❤️", "😂", "🔥", "👏", "✨"];

  @override
  void initState() {
    super.initState();
    _matchNameState = widget.matchName;
    _matchPhotoState = widget.matchPhotoUrl;
    _scrollController.addListener(_onScroll);
    _textController.addListener(_handleTypingChanged);
    Future.delayed(Duration.zero, _initializeChat);
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _typingStopTimer?.cancel();
    _reconnectTimer?.cancel();
    _textController.dispose();
    _recordTimer?.cancel();
    _recorder.dispose();
    for (final t in _audioPlaybackTimers.values) {
      t?.cancel();
    }
    _leaveAndDisconnectSocket();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (_nextCursor != null && !_isLoadingMore) _loadMoreMessages();
    }
  }

  void _leaveAndDisconnectSocket() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    if (_socket != null) {
      try {
        _emitTypingStop();
        _socket!.emit('leave_match', {'matchId': widget.matchId});
        _socket!.clearListeners();
        _socket!.disconnect();
      } catch (_) {}
      _socket = null;
    }
  }

  Future<void> _initializeChat() async {
    _apiClient = YaaroScope.of(context);
    _currentUserId = _apiClient.user?.id;
    if (!isBackendNumericId(widget.matchId)) {
      setState(() {
        _isLoading = false;
        _notice = 'Invalid match ID. Refresh your matches or log in again.';
      });
      return;
    }
    _fetchMatchDetails();
    // Load from local cache first for instant display
    await _loadCachedMessages();
    // Then sync from server in background
    _syncMessagesFromServer();
    _setupSocket();
  }

  Future<void> _loadCachedMessages() async {
    setState(() => _isLoading = true);
    try {
      final cached =
          await ChatRepository.instance.loadCachedMessages(widget.matchId);
      if (cached.isNotEmpty) {
        final incoming = cached
            .map((json) => ChatMessage.fromJson(json, _currentUserId ?? ''))
            .toList();
        _mergeAndSortMessages(incoming);
      }
    } catch (_) {
      // Cache miss is fine — will load from server
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncMessagesFromServer() async {
    try {
      final payload =
          await _apiClient.getMessages(widget.matchId, cursor: null);
      final rawMessages = payload['messages'] as List? ?? [];
      final messages = rawMessages.whereType<Map<String, dynamic>>().toList();

      if (messages.isNotEmpty) {
        // Cache to local DB using widget.matchId as the key so lookups work
        for (final msg in messages) {
          await ChatRepository.instance
              .cacheMessage(msg, conversationKey: widget.matchId);
        }
        // Update UI
        final incoming = messages
            .map((json) => ChatMessage.fromJson(json, _currentUserId ?? ''))
            .toList();
        _mergeAndSortMessages(incoming);
      }
      _nextCursor = payload['nextCursor']?.toString();
      _markUnreadAsRead();
    } catch (e) {
      // If server sync fails but we have cached data, user still sees messages
      if (_messages.isEmpty) {
        setState(() => _notice = e.toString());
      }
    }
  }

  Future<void> _fetchMatchDetails() async {
    try {
      // First try the conversations endpoint (uses conversation IDs)
      final conversations = await _apiClient.conversations();
      final found = conversations.cast<MatchItem?>().firstWhere(
            (i) => i!.id == widget.matchId,
            orElse: () => null,
          );
      if (found != null) {
        setState(() {
          _matchNameState = found.name;
          _matchPhotoState = found.photoUrl;
          if (found.lastActiveAt != null) _lastActiveAt = found.lastActiveAt;
        });
        return;
      }
      // Fallback: try matches endpoint (uses match IDs)
      final list = await _apiClient.matches();
      final m = list.cast<MatchItem?>().firstWhere(
            (i) => i!.id == widget.matchId,
            orElse: () => null,
          );
      if (m != null) {
        setState(() {
          _matchNameState = m.name;
          _matchPhotoState = m.photoUrl;
          if (m.lastActiveAt != null) _lastActiveAt = m.lastActiveAt;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMessages(String? cursor) async {
    if (cursor == null) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingMore = true);
    }
    try {
      final payload =
          await _apiClient.getMessages(widget.matchId, cursor: cursor);
      final rawMessages = payload['messages'] as List? ?? [];
      final incoming =
          rawMessages.whereType<Map<String, dynamic>>().map((json) {
        // Cache each message to local storage
        ChatRepository.instance
            .cacheMessage(json, conversationKey: widget.matchId);
        return ChatMessage.fromJson(json, _currentUserId ?? '');
      }).toList();
      _mergeAndSortMessages(incoming);
      _nextCursor = payload['nextCursor']?.toString();
      if (cursor == null) _markUnreadAsRead();
    } catch (e) {
      setState(() => _notice = e.toString());
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _mergeAndSortMessages(List<ChatMessage> incoming) {
    final map = <String, ChatMessage>{};
    for (final m in _messages) map[m.id] = m;
    for (final m in incoming) {
      if (m.isMine) {
        String? pendingId;
        for (final entry in map.entries) {
          if (entry.value.isPendingMatchFor(m)) {
            pendingId = entry.key;
            break;
          }
        }
        if (pendingId != null) map.remove(pendingId);
      }
      map[m.id] = m;
    }
    final sorted = map.values.toList()
      ..sort((a, b) =>
          DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));
    setState(() {
      _messages.clear();
      _messages.addAll(sorted);
    });
  }

  void _replaceMessage(String oldId, ChatMessage next) {
    final index = _messages.indexWhere((m) => m.id == oldId);
    if (index == -1) {
      _mergeAndSortMessages([next]);
      return;
    }
    setState(() {
      _messages[index] = next;
      _messages.sort((a, b) =>
          DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));
    });
  }

  void _handleTypingChanged() {
    // Rebuild so mic/send button toggles correctly
    setState(() {});
    if (_socket == null ||
        !_socket!.connected ||
        _textController.text.isEmpty) {
      _emitTypingStop();
      return;
    }
    if (!_hasSentTypingStart) {
      _hasSentTypingStart = true;
      _socket!.emit('typing_start', {'matchId': widget.matchId});
    }
    _typingStopTimer?.cancel();
    _typingStopTimer =
        Timer(const Duration(milliseconds: 500), _emitTypingStop);
  }

  void _emitTypingStop() {
    _typingStopTimer?.cancel();
    if (_hasSentTypingStart && _socket != null && _socket!.connected) {
      _socket!.emit('typing_stop', {'matchId': widget.matchId});
    }
    _hasSentTypingStart = false;
  }

  Future<void> _loadMoreMessages() async {
    if (_nextCursor == null || _isLoadingMore) return;
    await _loadMessages(_nextCursor);
  }

  void _markUnreadAsRead() {
    for (final m in _messages) {
      if (!m.isMine && !m.isRead) {
        _apiClient.markMessageRead(m.id).catchError((_) {});
        if (_socket != null && _socket!.connected) {
          _socket!.emit(
              'mark_read', {'matchId': widget.matchId, 'messageId': m.id});
        }
      }
    }
  }

  void _setupSocket() {
    final token = _apiClient.accessToken;
    if (token == null) return;
    _socket = io.io(
      socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .setTimeout(20000)
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .setReconnectionAttempts(99999)
          .disableAutoConnect()
          .build(),
    );
    _socket!.onConnect((_) {
      _socketEverConnected = true;
      _reconnectTimer?.cancel();
      if (_notice != null && _notice!.contains('reconnect')) {
        setState(() => _notice = null);
      } else {
        setState(() {});
      }
      _socket!.emitWithAck('join_match', {'matchId': widget.matchId},
          ack: (ackData) {
        if (ackData is Map) {
          if (ackData['success'] == true) {
            setState(() {
              _isOnline = ackData['isOnline'] == true;
              _otherUserId = ackData['otherUserId']?.toString();
              _lastActiveAt = ackData['lastActiveAt']?.toString();
              _realMatchId = ackData['matchId']?.toString();
            });
          } else {
            final msg = ackData['message']?.toString();
            setState(() => _notice =
                msg?.isNotEmpty == true ? msg! : 'Unable to join this chat.');
          }
        } else {
          setState(() => _notice = 'Unable to join this chat.');
        }
      });
    });
    _socket!.onDisconnect((_) {
      if (_socketEverConnected && mounted) setState(() => _isOnline = false);
    });
    _socket!.onConnectError((_) {
      if (_socketEverConnected && mounted)
        setState(() => _notice = 'Chat connection lost – reconnecting…');
    });
    _socket!.onError((_) {
      if (_socketEverConnected && mounted)
        setState(() => _notice = 'Chat connection lost – reconnecting…');
    });
    void handleMsg(dynamic data) {
      if (data is Map) {
        final jsonData = Map<String, dynamic>.from(data);
        final msg = ChatMessage.fromJson(jsonData, _currentUserId ?? '');
        // Accept messages for this conversation (compare by matchId OR conversationId)
        final msgMatchId = jsonData['matchId']?.toString() ?? '';
        final msgConvId = jsonData['conversationId']?.toString() ?? '';
        if (msgMatchId == widget.matchId ||
            msgConvId == widget.matchId ||
            msg.matchId == widget.matchId) {
          // Cache to local storage using the screen's key
          ChatRepository.instance
              .cacheMessage(jsonData, conversationKey: widget.matchId);
          _mergeAndSortMessages([msg]);
          _socket!.emit(
              'mark_read', {'matchId': widget.matchId, 'messageId': msg.id});
          _apiClient.markMessageRead(msg.id).catchError((_) {});
        }
      }
    }

    _socket!.on('new_message', handleMsg);
    _socket!.on('receive_message', handleMsg);
    _socket!.on('message_delivered', (data) {
      if (data is Map) {
        final evMatchId = data['matchId']?.toString();
        if (evMatchId == widget.matchId || evMatchId == _realMatchId) {
          final mid = data['messageId']?.toString();
          setState(() {
            for (var i = 0; i < _messages.length; i++) {
              if (_messages[i].id == mid && _messages[i].isMine) {
                _messages[i] =
                    _messages[i].copyWith(deliveryStatus: 'delivered');
              }
            }
          });
        }
      }
    });
    _socket!.on('message_read', (data) {
      if (data is Map) {
        final evMatchId = data['matchId']?.toString();
        final readAt = data['readAt']?.toString();
        if (evMatchId == widget.matchId || evMatchId == _realMatchId) {
          setState(() {
            for (var i = 0; i < _messages.length; i++) {
              if (_messages[i].isMine) {
                _messages[i] =
                    _messages[i].copyWith(isRead: true, readAt: readAt);
              }
            }
          });
        }
      }
    });
    _socket!.on('message_reaction', (data) {
      if (data is Map && data['message'] is Map<String, dynamic>) {
        final updated = ChatMessage.fromJson(
            data['message'] as Map<String, dynamic>, _currentUserId ?? '');
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == updated.id);
          if (idx != -1) _messages[idx] = updated;
        });
      }
    });
    _socket!.on('presence_update', (data) {
      if (data is Map) {
        final online = data['isOnline'] == true;
        setState(() {
          _isOnline = online;
          if (!online) {
            // They just went offline, set last active to now
            _lastActiveAt = DateTime.now().toUtc().toIso8601String();
          }
        });
      }
    });
    _socket!.on('typing_start', (data) {
      if (data is Map) {
        final evMatchId = data['matchId']?.toString();
        if (evMatchId == widget.matchId || evMatchId == _realMatchId)
          setState(() => _isOtherTyping = true);
      }
    });
    _socket!.on('typing_stop', (data) {
      if (data is Map) {
        final evMatchId = data['matchId']?.toString();
        if (evMatchId == widget.matchId || evMatchId == _realMatchId)
          setState(() => _isOtherTyping = false);
      }
    });
    _socket!.connect();
  }

  // -------------------------------------------------------------------------
  // Send helpers
  // -------------------------------------------------------------------------
  void _handleKeyboardContentInserted(KeyboardInsertedContent content) {
    final uri = content.uri;
    if (uri.isEmpty) return;
    // If the keyboard provides an HTTP URL (Tenor/Giphy), send as GIF directly
    if (uri.startsWith('http://') || uri.startsWith('https://')) {
      _sendGif(uri);
    } else if (content.hasData && content.data != null) {
      // Keyboard provided raw bytes — upload as media
      _sendGifBytes(content.data!, content.mimeType);
    } else {
      // Fallback: try to read the content:// URI via file
      _sendGifFromContentUri(uri);
    }
  }

  Future<void> _sendGifBytes(List<int> bytes, String mimeType) async {
    try {
      setState(() => _isUploading = true);
      final ext = mimeType.contains('gif') ? 'gif' : 'png';
      final res = await _apiClient.sendMediaMessage(
        widget.matchId,
        bytes,
        filename: 'keyboard_image.$ext',
        mimeType: mimeType,
        fieldName: 'image',
        type: mimeType.contains('gif') ? 'gif' : 'photo',
      );
      if (res['success'] == true && res['message'] is Map<String, dynamic>) {
        _mergeAndSortMessages(
            [ChatMessage.fromJson(res['message'], _currentUserId ?? '')]);
      }
    } catch (e) {
      setState(() => _notice = 'Failed to send image: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _sendGifFromContentUri(String uri) async {
    try {
      final file = dart_io.File(uri.replaceFirst('content://', ''));
      if (!await file.exists()) {
        setState(() => _notice = 'Could not access the selected image.');
        return;
      }
      final bytes = await file.readAsBytes();
      await _sendGifBytes(bytes, 'image/gif');
    } catch (e) {
      setState(() => _notice = 'Failed to send GIF: $e');
    }
  }

  Future<void> _sendGif(String gifUrl) async {
    if (gifUrl.isEmpty) return;
    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final pending = ChatMessage(
      id: tempId,
      matchId: widget.matchId,
      senderId: _currentUserId ?? '',
      type: 'gif',
      content: '',
      mediaUrl: gifUrl,
      reactions: const [],
      isMine: true,
      isRead: false,
      isDeleted: false,
      createdAt: DateTime.now().toIso8601String(),
      deliveryStatus: 'sending',
    );
    _mergeAndSortMessages([pending]);
    try {
      final res = await _apiClient.sendMessage(
        widget.matchId,
        '',
        'gif',
        mediaUrl: gifUrl,
      );
      if (res['success'] == true && res['message'] is Map<String, dynamic>) {
        _replaceMessage(
            tempId,
            ChatMessage.fromJson(res['message'], _currentUserId ?? '')
                .copyWith(deliveryStatus: 'sent'));
      }
    } catch (e) {
      setState(() => _notice = 'Failed to send GIF: $e');
      _replaceMessage(tempId, pending.copyWith(deliveryStatus: 'failed'));
    }
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _emitTypingStop();
    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final pending = ChatMessage(
      id: tempId,
      matchId: widget.matchId,
      senderId: _currentUserId ?? '',
      type: 'text',
      content: text,
      reactions: const [],
      isMine: true,
      isRead: false,
      isDeleted: false,
      createdAt: DateTime.now().toIso8601String(),
      deliveryStatus: 'sending',
    );
    _mergeAndSortMessages([pending]);
    if (_socket != null && _socket!.connected) {
      _socket!.emitWithAck(
        'send_message',
        {'matchId': widget.matchId, 'content': text, 'type': 'text'},
        ack: (ack) {
          if (ack is Map && ack['success'] == true) {
            if (ack['message'] is Map) {
              _replaceMessage(
                  tempId,
                  ChatMessage.fromJson(
                          Map<String, dynamic>.from(ack['message'] as Map),
                          _currentUserId ?? '')
                      .copyWith(deliveryStatus: 'sent'));
            } else {
              _replaceMessage(tempId, pending.copyWith(deliveryStatus: 'sent'));
            }
          } else if (ack is Map && ack['status'] == 402) {
            setState(() => _notice = ack['message']?.toString() ??
                'Free members can send 2 messages per day.');
            _replaceMessage(tempId, pending.copyWith(deliveryStatus: 'failed'));
          } else {
            _fallbackSendTextREST(text, tempId: tempId);
          }
        },
      );
    } else {
      await _fallbackSendTextREST(text, tempId: tempId);
    }
  }

  Future<void> _fallbackSendTextREST(String text, {String? tempId}) async {
    try {
      final res = await _apiClient.sendMessage(widget.matchId, text, 'text');
      if (res['success'] == true && res['message'] is Map<String, dynamic>) {
        final newMsg =
            ChatMessage.fromJson(res['message'], _currentUserId ?? '');
        if (tempId != null) {
          _replaceMessage(tempId, newMsg.copyWith(deliveryStatus: 'sent'));
        } else {
          _mergeAndSortMessages([newMsg]);
        }
      }
    } catch (e) {
      setState(() => _notice = e.toString());
      if (tempId != null) {
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (idx != -1)
          _replaceMessage(
              tempId, _messages[idx].copyWith(deliveryStatus: 'failed'));
      }
    }
  }

  /// Pick image from gallery or camera, optionally add a caption
  Future<void> _pickAndSendImage({required ImageSource source}) async {
    setState(() => _showAttachPanel = false);
    try {
      final picker = ImagePicker();
      final XFile? file =
          await picker.pickImage(source: source, imageQuality: 80);
      if (file == null) return;

      // Optional caption dialog
      String caption = '';
      if (mounted) {
        final result = await _showCaptionDialog(file.path);
        if (result == null) return; // user cancelled
        caption = result;
      }

      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

      setState(() => _isUploading = true);
      final res = await _apiClient.sendMediaMessage(
        widget.matchId,
        bytes,
        filename: file.name,
        mimeType: mime,
        fieldName: 'image',
        type: 'photo',
        caption: caption,
      );
      if (res['success'] == true && res['message'] is Map<String, dynamic>) {
        _mergeAndSortMessages(
            [ChatMessage.fromJson(res['message'], _currentUserId ?? '')]);
      }
    } catch (e) {
      setState(() => _notice = 'Failed to send image: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<String?> _showCaptionDialog(String imagePath) {
    final ctrl = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(dart_io.File(imagePath),
                  height: 200, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: TextStyle(color: YaaroColors.textFor(ctx)),
              decoration: InputDecoration(
                hintText: 'Add a caption…',
                hintStyle: TextStyle(color: _inputHintColor(ctx)),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: Text('Cancel',
                      style: TextStyle(color: YaaroColors.mutedFor(ctx))),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: YaaroColors.rose),
                  onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                  icon: const Icon(Icons.send, color: Colors.white, size: 16),
                  label:
                      const Text('Send', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendFile() async {
    setState(() => _showAttachPanel = false);
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.first;
      if (picked.bytes == null) return;

      setState(() => _isUploading = true);
      final ext = picked.extension?.toLowerCase() ?? 'bin';
      final mime = _mimeForExt(ext);
      final res = await _apiClient.sendMediaMessage(
        widget.matchId,
        picked.bytes!,
        filename: picked.name,
        mimeType: mime,
        fieldName: 'file',
        type: 'file',
      );
      if (res['success'] == true && res['message'] is Map<String, dynamic>) {
        _mergeAndSortMessages(
            [ChatMessage.fromJson(res['message'], _currentUserId ?? '')]);
      }
    } catch (e) {
      setState(() => _notice = 'Failed to send file: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  String _mimeForExt(String ext) {
    const map = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'gif': 'image/gif',
      'mp4': 'video/mp4',
      'mp3': 'audio/mpeg',
      'm4a': 'audio/m4a',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  // -------------------------------------------------------------------------
  // Voice recording
  // -------------------------------------------------------------------------
  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      setState(() => _notice = 'Microphone permission denied.');
      return;
    }
    final dir = await getTemporaryDirectory();
    _recordingPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
          encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100),
      path: _recordingPath!,
    );
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordSeconds++);
    });
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path == null) return;
    try {
      setState(() => _isUploading = true);
      final bytes = await dart_io.File(path).readAsBytes();
      final res = await _apiClient.sendVoiceMessage(widget.matchId, bytes);
      if (res['success'] == true && res['message'] is Map<String, dynamic>) {
        _mergeAndSortMessages(
            [ChatMessage.fromJson(res['message'], _currentUserId ?? '')]);
      }
    } catch (e) {
      setState(() => _notice = 'Failed to send voice: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.cancel();
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
  }

  // -------------------------------------------------------------------------
  // Calls
  // -------------------------------------------------------------------------
  void _startCall({required bool isVideo}) {
    startZegoCall(
      context,
      matchId: widget.matchId,
      otherUserName: _matchNameState,
      otherUserPhotoUrl: _matchPhotoState,
      isVideo: isVideo,
    );
  }

  // -------------------------------------------------------------------------
  // Reactions / moderation
  // -------------------------------------------------------------------------
  Future<void> _react(String messageId, String emoji) async {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('react_message', {'messageId': messageId, 'emoji': emoji});
    } else {
      try {
        await _apiClient.reactToMessage(messageId, emoji);
        _loadMessages(null);
      } catch (_) {}
    }
    setState(() => _selectedMessageId = null);
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _apiClient.deleteMessage(messageId);
      setState(() {
        for (var i = 0; i < _messages.length; i++) {
          if (_messages[i].id == messageId) {
            _messages[i] = _messages[i]
                .copyWith(isDeleted: true, content: null, mediaUrl: null);
          }
        }
      });
    } catch (_) {
      setState(() => _notice = 'Failed to delete message.');
    }
    setState(() => _selectedMessageId = null);
  }

  Future<void> _reportMessage(String messageId) async {
    try {
      await _apiClient.reportMessage(messageId);
      setState(() => _notice = 'Safety report filed.');
    } catch (_) {
      setState(() => _notice = 'Failed to report message.');
    }
    setState(() => _selectedMessageId = null);
  }

  // -------------------------------------------------------------------------
  // Audio playback simulation
  // -------------------------------------------------------------------------
  void _toggleAudioPlayback(ChatMessage message) {
    final msgId = message.id;
    final isPlaying = _audioPlayingState[msgId] ?? false;
    if (isPlaying) {
      setState(() {
        _audioPlayingState[msgId] = false;
        _audioPlaybackTimers[msgId]?.cancel();
      });
    } else {
      setState(() => _audioPlayingState[msgId] = true);
      final totalDuration = message.durationSeconds ?? 8;
      final step = 0.1 / totalDuration;
      _audioPlaybackTimers[msgId] = Timer.periodic(
        const Duration(milliseconds: 100),
        (timer) {
          final pos = _audioPlaybackPosition[msgId] ?? 0.0;
          if (pos >= 1.0) {
            timer.cancel();
            setState(() {
              _audioPlayingState[msgId] = false;
              _audioPlaybackPosition[msgId] = 0.0;
            });
          } else {
            setState(() => _audioPlaybackPosition[msgId] = pos + step);
          }
        },
      );
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final selectedMsg = _selectedMessageId != null
        ? _messages.firstWhere((m) => m.id == _selectedMessageId,
            orElse: () => ChatMessage(
                id: '',
                matchId: '',
                senderId: '',
                type: 'system',
                reactions: [],
                isMine: false,
                isRead: false,
                isDeleted: false,
                createdAt: ''))
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
          createdAt: ''),
    );

    return Scaffold(
      backgroundColor: _scaffoldBg(context),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_notice != null) _buildNoticeBanner(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: YaaroColors.rose))
                : Stack(
                    children: [
                      _messages.isEmpty
                          ? Center(
                              child: Text('Say hello to start the chat.',
                                  style: TextStyle(
                                      color: YaaroColors.mutedFor(context),
                                      fontSize: 15)))
                          : ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final showSeen = lastMineRead.id.isNotEmpty &&
                                    message.id == lastMineRead.id;
                                return Column(
                                  crossAxisAlignment: message.isMine
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    _buildMessageBubble(message),
                                    if (showSeen && message.readAt != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 4, right: 8, bottom: 8),
                                        child: Text(
                                          'Seen ${DateFormat('jm').format(DateTime.parse(message.readAt!))}',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: _seenColor(context)),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                      if (_isUploading)
                        Positioned.fill(
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Container(
                                color: Colors.black.withOpacity(0.25),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                          color: YaaroColors.rose),
                                      SizedBox(height: 12),
                                      Text('Uploading…',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          if (selectedMsg != null && selectedMsg.id.isNotEmpty)
            _buildReactionPanel(selectedMsg),
          if (_showAttachPanel) _buildAttachPanel(),
          _buildComposer(),
        ],
      ),
    );
  }

  String _formatLastActive(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'Offline';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return 'Offline';
    final now = DateTime.now().toUtc();
    final diff = now.difference(date.toUtc());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return 'Active ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Active ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Active yesterday';
    if (diff.inDays < 7) return 'Active ${diff.inDays}d ago';
    return 'Active ${DateFormat('MMM d').format(date.toLocal())}';
  }

  String _statusText() {
    if (_isOtherTyping) return 'Typing…';
    if (_isOnline) return 'Online now';
    return _formatLastActive(_lastActiveAt);
  }

  PreferredSizeWidget _buildAppBar() {
    final statusText = _statusText();
    final isActive = _isOtherTyping || _isOnline;

    return AppBar(
      backgroundColor: _surfaceColor(context),
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
                backgroundColor: _surfaceAltColor(context),
                child: _matchPhotoState == null
                    ? Icon(Icons.person,
                        color: YaaroColors.isDarkFor(context)
                            ? Colors.white54
                            : Colors.black38)
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
                    border: Border.all(color: _surfaceColor(context), width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_matchNameState,
                  style: TextStyle(
                      color: YaaroColors.textFor(context),
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
              Text(
                statusText,
                style: TextStyle(
                  color: isActive
                      ? YaaroColors.teal
                      : YaaroColors.mutedFor(context),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone, color: YaaroColors.rose),
          tooltip: 'Voice call',
          onPressed: () => _startCall(isVideo: false),
        ),
        IconButton(
          icon: const Icon(Icons.videocam, color: YaaroColors.rose),
          tooltip: 'Video call',
          onPressed: () => _startCall(isVideo: true),
        ),
        const SizedBox(width: 4),
      ],
      elevation: 1,
    );
  }

  Widget _buildNoticeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: YaaroColors.saffron.withOpacity(0.18),
      child: Row(
        children: [
          Expanded(
            child: Text(_notice!,
                style: const TextStyle(
                    color: YaaroColors.saffron,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: YaaroColors.saffron, size: 16),
            onPressed: () => setState(() => _notice = null),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachPanel() {
    final items = [
      _AttachItem(
          icon: Icons.photo_library_rounded,
          label: 'Gallery',
          color: YaaroColors.rose,
          onTap: () => _pickAndSendImage(source: ImageSource.gallery)),
      _AttachItem(
          icon: Icons.camera_alt_rounded,
          label: 'Camera',
          color: YaaroColors.teal,
          onTap: () => _pickAndSendImage(source: ImageSource.camera)),
      _AttachItem(
          icon: Icons.insert_drive_file_rounded,
          label: 'File',
          color: YaaroColors.saffron,
          onTap: _pickAndSendFile),
    ];
    return Container(
      color: _surfaceColor(context),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items
            .map((item) => GestureDetector(
                  onTap: item.onTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: item.color, size: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(item.label,
                          style: TextStyle(
                              fontSize: 12,
                              color: YaaroColors.textFor(context),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildComposer() {
    final isDark = YaaroColors.isDarkFor(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        border: Border(top: BorderSide(color: YaaroColors.lineFor(context))),
      ),
      child: _isRecording ? _buildRecordingBar() : _buildTextBar(isDark),
    );
  }

  Widget _buildTextBar(bool isDark) {
    return Row(
      children: [
        // attachment toggle
        IconButton(
          icon: Icon(
            _showAttachPanel ? Icons.close : Icons.attach_file_rounded,
            color: _showAttachPanel
                ? YaaroColors.rose
                : YaaroColors.mutedFor(context),
          ),
          onPressed: () => setState(() => _showAttachPanel = !_showAttachPanel),
        ),
        // text field
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: _surfaceAltColor(context),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _textController,
              maxLines: 4,
              minLines: 1,
              style: TextStyle(color: YaaroColors.textFor(context)),
              contentInsertionConfiguration: ContentInsertionConfiguration(
                allowedMimeTypes: const [
                  'image/gif',
                  'image/png',
                  'image/jpeg'
                ],
                onContentInserted: (KeyboardInsertedContent content) {
                  _handleKeyboardContentInserted(content);
                },
              ),
              decoration: InputDecoration(
                hintText: 'Message…',
                hintStyle: TextStyle(color: _inputHintColor(context)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (_) => _sendText(),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // mic or send
        _textController.text.trim().isEmpty
            ? GestureDetector(
                onLongPressStart: (_) => _startRecording(),
                onLongPressEnd: (_) => _stopAndSendRecording(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: YaaroColors.rose.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_rounded, color: YaaroColors.rose),
                ),
              )
            : GestureDetector(
                onTap: _sendText,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: YaaroColors.rose,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
      ],
    );
  }

  Widget _buildRecordingBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: YaaroColors.rose),
          onPressed: _cancelRecording,
          tooltip: 'Cancel',
        ),
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.fiber_manual_record,
                  color: YaaroColors.rose, size: 14),
              const SizedBox(width: 6),
              Text(
                'Recording  0:${_recordSeconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    color: YaaroColors.rose, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _stopAndSendRecording,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
                color: YaaroColors.rose, shape: BoxShape.circle),
            child: const Icon(Icons.stop_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isMine = message.isMine;
    final timeStr = DateFormat('jm').format(DateTime.parse(message.createdAt));
    return InkWell(
      onLongPress: () => setState(() => _selectedMessageId = message.id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isDeleted
              ? _deletedBubbleBg(context)
              : isMine
                  ? YaaroColors.rose
                  : _surfaceAltColor(context),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: Border.all(
            color: message.isDeleted
                ? _deletedBubbleBorder(context)
                : Colors.transparent,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.isDeleted)
              Text('Message deleted',
                  style: TextStyle(
                      color: YaaroColors.mutedFor(context),
                      fontStyle: FontStyle.italic,
                      fontSize: 14))
            else if (message.type == 'photo' ||
                message.type == 'image' ||
                message.type == 'gif')
              _buildImageBubbleContent(message)
            else if (message.type == 'file')
              _buildFileBubbleContent(message, isMine)
            else if (message.type == 'voice' || message.type == 'audio')
              _buildVoicePlayer(message)
            else
              Text(message.content ?? '',
                  style: TextStyle(
                      color: _bubbleTextColor(context, isMine: isMine),
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
            // caption under image
            if ((message.type == 'photo' || message.type == 'image') &&
                (message.content?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(message.content!,
                    style: TextStyle(
                        color: _bubbleTextColor(context, isMine: isMine),
                        fontSize: 13)),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timeStr,
                    style: TextStyle(
                        color:
                            isMine ? Colors.white54 : _timestampColor(context),
                        fontSize: 10)),
                if (!message.isDeleted && message.isMine) ...[
                  const SizedBox(width: 6),
                  _buildDeliveryTick(message),
                ],
              ],
            ),
            if (message.reactions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: _reactionBadgeBg(context),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(message.reactions.map((r) => r.emoji).join(' '),
                    style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBubbleContent(ChatMessage message) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        message.mediaUrl ?? '',
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const SizedBox(
                height: 150,
                child: Center(
                    child: CircularProgressIndicator(color: Colors.white30))),
        errorBuilder: (_, __, ___) => Container(
            height: 150,
            color: Colors.white10,
            child: const Center(
                child: Icon(Icons.broken_image, color: Colors.white38))),
      ),
    );
  }

  Widget _buildFileBubbleContent(ChatMessage message, bool isMine) {
    final filename =
        message.content?.isNotEmpty == true ? message.content! : 'File';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file_rounded,
            color: isMine ? Colors.white70 : YaaroColors.mutedFor(context),
            size: 28),
        const SizedBox(width: 8),
        Flexible(
          child: Text(filename,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: _bubbleTextColor(context, isMine: isMine),
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildDeliveryTick(ChatMessage message) {
    if (message.deliveryStatus == 'failed') {
      return const Icon(Icons.error_outline, size: 13, color: Colors.white70);
    }
    if (message.deliveryStatus == 'sending') {
      return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
              strokeWidth: 1.4, color: Colors.white54));
    }
    if (message.isRead || message.deliveryStatus == 'read') {
      return const Icon(Icons.done_all, size: 14, color: YaaroColors.teal);
    }
    if (message.deliveryStatus == 'delivered') {
      return const Icon(Icons.done_all, size: 14, color: Colors.white54);
    }
    return const Icon(Icons.check, size: 14, color: Colors.white54);
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
              size: 32),
          onPressed: () => _toggleAudioPlayback(message),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                  value: progress,
                  color: Colors.white,
                  backgroundColor: Colors.white30),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0:${elapsed.toString().padLeft(2, '0')}',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white70)),
                  Text('0:${duration.toString().padLeft(2, '0')}',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white70)),
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
      color: _surfaceColor(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _reactionChoices
                .map((emoji) => InkWell(
                      onTap: () => _react(message.id, emoji),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ))
                .toList(),
          ),
          Divider(color: YaaroColors.lineFor(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (message.isMine)
                TextButton.icon(
                  onPressed: () => _deleteMessage(message.id),
                  icon: const Icon(Icons.delete, color: YaaroColors.rose),
                  label: const Text('Delete',
                      style: TextStyle(color: YaaroColors.rose)),
                ),
              TextButton.icon(
                onPressed: () => _reportMessage(message.id),
                icon: const Icon(Icons.flag, color: YaaroColors.saffron),
                label: const Text('Report',
                    style: TextStyle(color: YaaroColors.saffron)),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedMessageId = null),
                child: Text('Cancel',
                    style: TextStyle(color: YaaroColors.mutedFor(context))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper data class for attach panel items
// ---------------------------------------------------------------------------
class _AttachItem {
  const _AttachItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

// ---------------------------------------------------------------------------
// ChatMessage model
// ---------------------------------------------------------------------------
class ChatMessage {
  const ChatMessage({
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
    this.deliveryStatus = 'sent',
  });

  final String id;
  final String matchId;
  final String senderId;
  final String type;
  final String? content;
  final String? mediaUrl;
  final int? durationSeconds;
  final List<MessageReaction> reactions;
  final bool isMine;
  final bool isRead;
  final String? readAt;
  final bool isDeleted;
  final String createdAt;
  final String deliveryStatus;

  factory ChatMessage.fromJson(
      Map<String, dynamic> json, String currentUserId) {
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
      isMine: json['senderId']?.toString() == currentUserId ||
          json['isMine'] == true,
      isRead: json['isRead'] == true,
      readAt: json['readAt']?.toString(),
      isDeleted: json['isDeleted'] == true,
      createdAt:
          json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      deliveryStatus: json['isRead'] == true ? 'read' : 'sent',
    );
  }

  bool isPendingMatchFor(ChatMessage other) {
    if (!id.startsWith('local-') || deliveryStatus == 'failed') return false;
    return isMine &&
        other.isMine &&
        matchId == other.matchId &&
        type == other.type &&
        (content ?? '') == (other.content ?? '') &&
        (mediaUrl ?? '') == (other.mediaUrl ?? '');
  }

  ChatMessage copyWith({
    bool? isRead,
    String? readAt,
    bool? isDeleted,
    String? content,
    String? mediaUrl,
    String? deliveryStatus,
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
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }
}

class MessageReaction {
  const MessageReaction({required this.userId, required this.emoji});
  final String userId;
  final String emoji;
  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      MessageReaction(
        userId: json['userId']?.toString() ?? '',
        emoji: json['emoji']?.toString() ?? '',
      );
}
