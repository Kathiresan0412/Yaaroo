import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/models/chat_message.dart';
import '../../../main.dart' show YaaroColors;
import '../../../shared/widgets/offline_indicator.dart';
import '../../auth/providers/auth_providers.dart';
import '../../calling/data/calling_service.dart';
import '../data/chat_service.dart';
import '../providers/chat_providers.dart';

/// Provides the [ZegoCallingService] singleton.
final callingServiceProvider = Provider<ZegoCallingService>((ref) {
  return ZegoCallingService();
});

/// A real-time chat screen backed by Firestore.
///
/// Receives a [matchId] to load messages via [chatMessagesProvider] and
/// optionally a [matchName] for the AppBar title.
///
/// Requirements: 13.2, 13.3, 13.4, 13.8, 14.1, 14.2, 14.3, 14.4
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    required this.matchId,
    required this.matchName,
    this.matchPhotoUrl,
    this.targetUid,
    super.key,
  });

  final String matchId;
  final String matchName;
  final String? matchPhotoUrl;

  /// The other user's UID, needed for calling.
  final String? targetUid;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  /// Tracks messages that failed to send so we can show error + retry.
  final List<_FailedMessage> _failedMessages = [];

  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Send text message
  // ---------------------------------------------------------------------------
  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      final chatService = ref.read(chatServiceProvider);
      await chatService.sendTextMessage(
        widget.matchId,
        currentUser.uid,
        text,
      );
    } on MessageValidationException catch (e) {
      _showSnackBar(e.message);
    } on MessageSendException catch (e) {
      setState(() {
        _failedMessages.add(_FailedMessage(
          text: e.retainedText ?? text,
          type: _FailedMessageType.text,
        ));
      });
    } catch (e) {
      setState(() {
        _failedMessages.add(_FailedMessage(
          text: text,
          type: _FailedMessageType.text,
        ));
      });
    } finally {
      setState(() => _isSending = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Send image message
  // ---------------------------------------------------------------------------
  Future<void> _pickAndSendImage() async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    setState(() => _isSending = true);

    try {
      final chatService = ref.read(chatServiceProvider);
      await chatService.sendImageMessage(
        widget.matchId,
        currentUser.uid,
        File(pickedFile.path),
      );
    } on MessageSendException catch (e) {
      setState(() {
        _failedMessages.add(_FailedMessage(
          imageFile: e.retainedImage ?? File(pickedFile.path),
          type: _FailedMessageType.image,
        ));
      });
    } catch (e) {
      setState(() {
        _failedMessages.add(_FailedMessage(
          imageFile: File(pickedFile.path),
          type: _FailedMessageType.image,
        ));
      });
    } finally {
      setState(() => _isSending = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Retry failed message
  // ---------------------------------------------------------------------------
  Future<void> _retryMessage(_FailedMessage failed) async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    setState(() {
      _failedMessages.remove(failed);
      _isSending = true;
    });

    try {
      final chatService = ref.read(chatServiceProvider);
      if (failed.type == _FailedMessageType.text && failed.text != null) {
        await chatService.sendTextMessage(
          widget.matchId,
          currentUser.uid,
          failed.text!,
        );
      } else if (failed.type == _FailedMessageType.image &&
          failed.imageFile != null) {
        await chatService.sendImageMessage(
          widget.matchId,
          currentUser.uid,
          failed.imageFile!,
        );
      }
    } on MessageValidationException catch (e) {
      _showSnackBar(e.message);
    } on MessageSendException {
      // Re-add to failed queue
      setState(() => _failedMessages.add(failed));
    } catch (_) {
      setState(() => _failedMessages.add(failed));
    } finally {
      setState(() => _isSending = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Calling
  // ---------------------------------------------------------------------------
  Future<void> _startVideoCall() async {
    if (OfflineGuard.guardAction(context, ref, 'Video calling')) return;
    await _initiateCall(isVideo: true);
  }

  Future<void> _startAudioCall() async {
    if (OfflineGuard.guardAction(context, ref, 'Audio calling')) return;
    await _initiateCall(isVideo: false);
  }

  Future<void> _initiateCall({required bool isVideo}) async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    // Determine target UID from the matchId if not explicitly provided
    final targetUid = widget.targetUid ?? _deriveTargetUid(currentUser.uid);
    if (targetUid == null) {
      _showSnackBar('Unable to determine call recipient.');
      return;
    }

    try {
      final callingService = ref.read(callingServiceProvider);
      if (isVideo) {
        await callingService.startVideoCall(
          currentUser.uid,
          currentUser.displayName ?? 'User',
          targetUid,
        );
      } else {
        await callingService.startAudioCall(
          currentUser.uid,
          currentUser.displayName ?? 'User',
          targetUid,
        );
      }
    } on CallingException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Call could not be started. Please try again.');
    }
  }

  /// Derives the other user's UID from the matchId (format: uid1_uid2 sorted).
  String? _deriveTargetUid(String currentUid) {
    final parts = widget.matchId.split('_');
    if (parts.length == 2) {
      return parts.firstWhere((p) => p != currentUid, orElse: () => parts.last);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.matchId));
    final currentUser = ref.watch(authStateProvider).value;
    final currentUid = currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.matchPhotoUrl != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(widget.matchPhotoUrl!),
                ),
              ),
            Expanded(
              child: Text(
                widget.matchName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _startAudioCall,
            icon: const Icon(Icons.phone),
            tooltip: 'Audio call',
          ),
          IconButton(
            onPressed: _startVideoCall,
            icon: const Icon(Icons.videocam),
            tooltip: 'Video call',
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => _buildErrorState(error),
              data: (messages) => _buildMessageList(messages, currentUid),
            ),
          ),
          // Failed messages indicator
          if (_failedMessages.isNotEmpty) _buildFailedMessagesBar(),
          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------
  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: YaaroColors.rose,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load messages',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: YaaroColors.textFor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: YaaroColors.mutedFor(context),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(chatMessagesProvider(widget.matchId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Message list
  // ---------------------------------------------------------------------------
  Widget _buildMessageList(List<ChatMessage> messages, String currentUid) {
    if (messages.isEmpty && _failedMessages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Say hello!',
          style: TextStyle(
            color: YaaroColors.mutedFor(context),
            fontSize: 15,
          ),
        ),
      );
    }

    // Messages are already in ascending timestamp order from the provider.
    // Scroll to bottom when new messages arrive.
    _scrollToBottom();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMine = message.senderId == currentUid;
        final showTimestamp = _shouldShowTimestamp(messages, index);

        return Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showTimestamp)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: YaaroColors.mutedFor(context),
                    ),
                  ),
                ),
              ),
            _buildMessageBubble(message, isMine),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Message bubble
  // ---------------------------------------------------------------------------
  Widget _buildMessageBubble(ChatMessage message, bool isMine) {
    final bubbleColor = isMine
        ? YaaroColors.rose
        : (YaaroColors.isDarkFor(context)
            ? YaaroColors.surfaceAlt
            : const Color(0xFFEBECF0));

    final textColor = isMine ? Colors.white : YaaroColors.textFor(context);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isMine ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isMine ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: message.type == 'image' && message.imageUrl != null
            ? _buildImageMessageContent(message, textColor)
            : _buildTextMessageContent(message, textColor),
      ),
    );
  }

  Widget _buildTextMessageContent(ChatMessage message, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        message.text,
        style: TextStyle(
          fontSize: 15,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildImageMessageContent(ChatMessage message, Color textColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        message.imageUrl!,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: 200,
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 200,
            color: YaaroColors.surfaceAltFor(context),
            child: const Center(
              child: Icon(Icons.broken_image, size: 40),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Failed messages bar
  // ---------------------------------------------------------------------------
  Widget _buildFailedMessagesBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.red.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: _failedMessages.map((failed) {
          final label = failed.type == _FailedMessageType.text
              ? 'Text: "${_truncate(failed.text ?? '', 30)}"'
              : 'Image attachment';
          return Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to send: $label',
                  style: const TextStyle(fontSize: 13, color: Colors.red),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => _retryMessage(failed),
                child: const Text('Retry'),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Input bar
  // ---------------------------------------------------------------------------
  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: YaaroColors.isDarkFor(context)
              ? YaaroColors.surface
              : Colors.white,
          border: Border(
            top: BorderSide(
              color: YaaroColors.lineFor(context),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Image attachment button
            IconButton(
              onPressed: _isSending ? null : _pickAndSendImage,
              icon: Icon(
                Icons.image,
                color: YaaroColors.mutedFor(context),
              ),
              tooltip: 'Attach image',
            ),
            // Text field
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(
                    color: YaaroColors.mutedFor(context),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: YaaroColors.lineFor(context),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: YaaroColors.lineFor(context),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: YaaroColors.rose,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => _sendTextMessage(),
              ),
            ),
            const SizedBox(width: 6),
            // Send button
            IconButton(
              onPressed: _isSending ? null : _sendTextMessage,
              icon: Icon(
                Icons.send,
                color: _isSending
                    ? YaaroColors.mutedFor(context)
                    : YaaroColors.rose,
              ),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Timestamp display helpers
  // ---------------------------------------------------------------------------
  bool _shouldShowTimestamp(List<ChatMessage> messages, int index) {
    if (index == 0) return true;
    final current = messages[index].timestamp;
    final previous = messages[index - 1].timestamp;
    // Show timestamp if gap > 5 minutes
    return current.difference(previous).inMinutes > 5;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDay == today) {
      return DateFormat.jm().format(timestamp);
    } else if (today.difference(messageDay).inDays == 1) {
      return 'Yesterday ${DateFormat.jm().format(timestamp)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}…';
  }
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------
enum _FailedMessageType { text, image }

class _FailedMessage {
  final String? text;
  final File? imageFile;
  final _FailedMessageType type;

  const _FailedMessage({
    this.text,
    this.imageFile,
    required this.type,
  });
}
