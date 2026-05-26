import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../main.dart' show YaaroColors;

class WebRTCCallScreen extends StatefulWidget {
  const WebRTCCallScreen({
    required this.socket,
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    required this.isVideo,
    this.otherUserPhotoUrl,
    super.key,
  });

  final io.Socket socket;
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final bool isVideo;

  @override
  State<WebRTCCallScreen> createState() => _WebRTCCallScreenState();
}

class _WebRTCCallScreenState extends State<WebRTCCallScreen> {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isVideoOff = false;
  String _status = 'Calling...';
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _startCallFlow();
    _setupSignalListeners();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    widget.socket.off('webrtc_signal');
    _timer?.cancel();
    _localStream?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        _status = 'Active Call: ${_formatDuration(_seconds)}';
      });
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  void _setupSignalListeners() {
    widget.socket.on('webrtc_signal', (data) async {
      if (data is Map) {
        final type = data['type']?.toString();
        final sdp = data['sdp'];
        final candidate = data['candidate'];

        if (type == 'offer' && sdp != null) {
          await _handleOffer(sdp.toString());
        } else if (type == 'answer' && sdp != null) {
          await _handleAnswer(sdp.toString());
        } else if (type == 'candidate' && candidate != null) {
          await _handleCandidate(candidate);
        } else if (type == 'hangup') {
          _closeAndExit();
        }
      }
    });
  }

  Future<void> _startCallFlow() async {
    try {
      // 1. Get media stream
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': widget.isVideo
            ? {
                'facingMode': 'user',
                'width': '640',
                'height': '480',
              }
            : false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;
      if (mounted) setState(() {});

      // 2. Create PeerConnection
      final Map<String, dynamic> configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      };

      _peerConnection = await createPeerConnection(configuration);

      // Add local stream tracks
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // Handle ice candidates
      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          widget.socket.emit('webrtc_signal', {
            'to': widget.otherUserId,
            'type': 'candidate',
            'candidate': {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            }
          });
        }
      };

      // Handle connection status
      _peerConnection!.onConnectionState = (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          if (mounted) {
            setState(() {
              _status = 'Connected';
            });
            _startTimer();
          }
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _closeAndExit();
        }
      };

      // Handle remote stream
      _peerConnection!.onTrack = (event) {
        if (event.streams.isNotEmpty && _remoteRenderer.srcObject == null) {
          _remoteRenderer.srcObject = event.streams[0];
          if (mounted) setState(() {});
        }
      };

      // 3. Initiate Offer
      setState(() => _status = 'Ringing...');
      
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      widget.socket.emit('webrtc_signal', {
        'to': widget.otherUserId,
        'type': 'offer',
        'sdp': offer.sdp,
      });

    } catch (e) {
      setState(() => _status = 'Call Setup Failed: $e');
    }
  }

  Future<void> _handleOffer(String sdp) async {
    if (_peerConnection == null) return;
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    widget.socket.emit('webrtc_signal', {
      'to': widget.otherUserId,
      'type': 'answer',
      'sdp': answer.sdp,
    });
  }

  Future<void> _handleAnswer(String sdp) async {
    if (_peerConnection == null) return;
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
  }

  Future<void> _handleCandidate(dynamic candidateData) async {
    if (_peerConnection == null) return;
    final candidate = RTCIceCandidate(
      candidateData['candidate']?.toString() ?? '',
      candidateData['sdpMid']?.toString() ?? '',
      candidateData['sdpMLineIndex'] as int? ?? 0,
    );
    await _peerConnection!.addCandidate(candidate);
  }

  void _toggleMute() {
    if (_localStream == null) return;
    final tracks = _localStream!.getAudioTracks();
    if (tracks.isNotEmpty) {
      final audioTrack = tracks.first;
      setState(() {
        _isMuted = !_isMuted;
        audioTrack.enabled = !_isMuted;
      });
    }
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
      // Note: Real devices can use flutter_audio_query or audioplayers if switching routes physically.
    });
  }

  void _toggleVideo() {
    if (_localStream == null || !widget.isVideo) return;
    final tracks = _localStream!.getVideoTracks();
    if (tracks.isNotEmpty) {
      final videoTrack = tracks.first;
      setState(() {
        _isVideoOff = !_isVideoOff;
        videoTrack.enabled = !_isVideoOff;
      });
    }
  }

  void _hangup() {
    widget.socket.emit('webrtc_signal', {
      'to': widget.otherUserId,
      'type': 'hangup',
    });
    _closeAndExit();
  }

  void _closeAndExit() {
    _timer?.cancel();
    _localStream?.dispose();
    _peerConnection?.close();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showRemoteVideo = widget.isVideo && _remoteRenderer.srcObject != null;
    final showLocalVideo = widget.isVideo && _localRenderer.srcObject != null && !_isVideoOff;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video Renderer (Full Screen)
            if (showRemoteVideo)
              Positioned.fill(
                child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
              )
            else
              // Avatar Placeholder
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundImage: widget.otherUserPhotoUrl != null
                          ? NetworkImage(widget.otherUserPhotoUrl!)
                          : null,
                      backgroundColor: YaaroColors.surfaceAlt,
                      child: widget.otherUserPhotoUrl == null
                          ? const Icon(Icons.person, size: 60, color: Colors.white54)
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.otherUserName,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 16, color: Colors.white54),
                    ),
                  ],
                ),
              ),

            // Local Video Preview (Picture in Picture)
            if (showLocalVideo)
              Positioned(
                top: 20,
                right: 20,
                width: 110,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                ),
              ),

            // Call Action Buttons (Bottom Bar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute Audio
                      _buildIconButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        color: _isMuted ? YaaroColors.rose : Colors.white24,
                        onPressed: _toggleMute,
                      ),
                      // Speaker Toggle
                      _buildIconButton(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        color: _isSpeakerOn ? YaaroColors.teal : Colors.white24,
                        onPressed: _toggleSpeaker,
                      ),
                      // Video Toggle
                      if (widget.isVideo)
                        _buildIconButton(
                          icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                          color: _isVideoOff ? YaaroColors.rose : Colors.white24,
                          onPressed: _toggleVideo,
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // End Call Button
                  FloatingActionButton(
                    onPressed: _hangup,
                    backgroundColor: YaaroColors.rose,
                    child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        iconSize: 28,
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
