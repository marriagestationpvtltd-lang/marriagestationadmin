import 'dart:async';
import 'dart:math';
import 'package:adminmrz/adminchat/services/pushservice.dart';
import 'package:adminmrz/settings/call_settings_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'tokengenerator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// No need for dart:html import

// Video call state progression: calling → ringing → connected
enum _VCallStatus { calling, ringing, connected }

class VideoCallScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String otherUserId;
  final String otherUserName;
  final bool isOutgoingCall;
  /// Called when the user taps the minimize button.  When provided the screen
  /// is assumed to be hosted in an overlay and will NOT call Navigator.pop.
  final VoidCallback? onMinimize;
  /// Called when the call ends.  When provided Navigator.pop is skipped.
  final VoidCallback? onEnd;
  /// Called when the call ends with (callType, status, durationSeconds).
  /// callType is always 'video'. status is 'answered' or 'missed'.
  final void Function(String callType, String status, int durationSeconds)? onCallEnded;

  const VideoCallScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.otherUserId,
    required this.otherUserName,
    this.isOutgoingCall = true,
    this.onMinimize,
    this.onEnd,
    this.onCallEnded,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine _engine;

  int _localUid = 0;
  int? _remoteUid;

  String _channel = '';
  String _token = '';

  bool _joined = false;
  bool _callActive = false;
  bool _micMuted = false;
  bool _speakerOn = false;
  bool _videoEnabled = true;
  bool _cameraFront = true;
  bool _ending = false;

  _VCallStatus _callStatus = _VCallStatus.calling;

  Timer? _timeoutTimer;
  Timer? _callTimer;
  Duration _duration = Duration.zero;

  late AudioPlayer _ringtonePlayer;
  Timer? _ringtoneRepeatTimer;

  StreamSubscription<DocumentSnapshot>? _callSignalSubscription;

  // Video renderers
  Widget? _localVideoView;
  Widget? _remoteVideoView;

  @override
  void initState() {
    super.initState();
    _ringtonePlayer = AudioPlayer();
    _setupAudioPlayer();
    _startCall();
  }

  void _setupAudioPlayer() {
    _ringtonePlayer.setReleaseMode(ReleaseMode.stop);
    _ringtonePlayer.onPlayerStateChanged.listen((PlayerState state) {
      // Schedule repeat when tone completes — state tracking is not needed here
      if (state == PlayerState.completed && widget.isOutgoingCall && !_ending) {
        _scheduleRepeat();
      }
    });
  }

  void _scheduleRepeat() {
    if (!mounted || _ending) return;
    final settings = context.read<CallSettingsProvider>();
    final interval = settings.repeatIntervalSeconds;
    _ringtoneRepeatTimer = Timer(Duration(seconds: interval), () {
      if (!mounted || _ending) return;
      _playRingtoneSingle();
    });
  }

  Future<void> _playRingtoneSingle() async {
    if (!widget.isOutgoingCall || _ending) return;
    try {
      final settings = context.read<CallSettingsProvider>();
      await _ringtonePlayer.stop();
      await _ringtonePlayer.setVolume(_speakerOn ? 1.0 : 0.8);
      await _ringtonePlayer.play(AssetSource(settings.selectedTone.asset));
    } catch (_) {}
  }

  Future<void> _playRingtone() async {
    if (!widget.isOutgoingCall) return;
    try {
      await _stopRingtone();
      final settings = context.read<CallSettingsProvider>();
      await _ringtonePlayer.setVolume(_speakerOn ? 1.0 : 0.8);
      await _ringtonePlayer.play(AssetSource(settings.selectedTone.asset));
    } catch (e) {
    }
  }

  Future<void> _stopRingtone() async {
    try {
      _ringtoneRepeatTimer?.cancel();
      await _ringtonePlayer.stop();
    } catch (_) {}
  }

  Future<void> _startCall() async {
    try {
      // Ringtone for outgoing calls
      if (widget.isOutgoingCall) {
        _playRingtone();
      }

      // Generate channel and token
      _localUid = Random().nextInt(999999);
      _channel =
      'call_${widget.currentUserId.substring(0, min(4, widget.currentUserId.length))}'
          '_${widget.otherUserId.substring(0, min(4, widget.otherUserId.length))}'
          '_${DateTime.now().millisecondsSinceEpoch}';

      if (_channel.length > 64) {
        _channel = _channel.substring(0, 64);
      }

      _token = await AgoraTokenService.getToken(
        channelName: _channel,
        uid: _localUid,
      );

      // Send call notification for outgoing calls
      if (widget.isOutgoingCall) {
        await NotificationService.sendVideoCallNotification(
          recipientUserId: widget.otherUserId,
          callerName: widget.currentUserName,
          channelName: _channel,
          callerId: widget.currentUserId,
          callerUid: _localUid.toString(),
          agoraAppId: AgoraTokenService.appId,
          agoraCertificate: 'SERVER_ONLY',
        );

        // Write call signal to Firestore so the user app can signal rejection in real-time.
        await FirebaseFirestore.instance
            .collection('call_signals')
            .doc(_channel)
            .set({
          'status': 'ringing',
          'callerId': widget.currentUserId,
          'receiverId': widget.otherUserId,
          'type': 'video',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Transition to "Ringing" — remote phone is now ringing
        if (mounted) {
          setState(() => _callStatus = _VCallStatus.ringing);
        }

        // Listen for rejection from the user's app.
        _callSignalSubscription = FirebaseFirestore.instance
            .collection('call_signals')
            .doc(_channel)
            .snapshots()
            .listen(
          (snap) async {
            if (!mounted || _ending) return;
            final data = snap.data();
            if (data != null && data['status'] == 'rejected') {
              await _endCall();
            }
          },
          onError: (_) {/* Firestore errors are non-fatal; timeout will still fire */},
        );
      }

      // Initialize Agora engine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: AgoraTokenService.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Enable audio and video
      await _engine.enableAudio();
      await _engine.enableVideo();

      // Start preview – triggers camera permission prompt
      await _engine.startPreview();

      // Register event handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (_, __) {
            if (mounted) {
              setState(() => _joined = true);
              _setupLocalVideo();
            }
          },
          onUserJoined: (_, uid, __) {
            if (mounted) {
              setState(() {
                _remoteUid = uid;
                _callStatus = _VCallStatus.connected;
              });
              _setupRemoteVideo(uid);
            }
            _stopRingtone();
            _startCallTimer();
          },
          onUserOffline: (_, __, ___) {
            _endCall();
          },
          onError: (code, msg) {},
        ),
      );

      // Set client role
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Join channel
      await _engine.joinChannel(
        token: _token,
        channelId: _channel,
        uid: _localUid,
        options: const ChannelMediaOptions(
          publishMicrophoneTrack: true,
          publishCameraTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      // Timeout after 30 seconds if no answer
      _timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (_remoteUid == null) {
          if (widget.isOutgoingCall) {
            NotificationService.sendMissedCallNotification(
              callerId: widget.currentUserId,
              callerName: widget.otherUserName,
            );
          }
          _endCall();
        }
      });
    } catch (e) {
      _exit();
    }
  }

  void _setupLocalVideo() {
    // Create a local video view
    final videoSurface = AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: 0), // 0 means local
      ),
    );
    setState(() {
      _localVideoView = videoSurface;
    });
  }

  void _setupRemoteVideo(int uid) {
    final videoSurface = AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: uid),
        connection: RtcConnection(channelId: _channel),
      ),
    );
    setState(() {
      _remoteVideoView = videoSurface;
    });
  }

  void _startCallTimer() {
    _timeoutTimer?.cancel();
    _callActive = true;

    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _duration += const Duration(seconds: 1));
    });
  }

  Future<void> _endCall() async {
    if (_ending) return;
    _ending = true;

    _callTimer?.cancel();
    _timeoutTimer?.cancel();

    await _callSignalSubscription?.cancel();
    _callSignalSubscription = null;

    // Clean up the Firestore call signal document.
    if (widget.isOutgoingCall) {
      FirebaseFirestore.instance
          .collection('call_signals')
          .doc(_channel)
          .delete()
          .catchError((_) {});
    }

    await _stopRingtone();

    if (_callActive) {
      await NotificationService.sendCallEndedNotification(
        recipientUserId: widget.otherUserId,
        callerName: widget.currentUserName,
        reason: 'ended',
        duration: _duration.inSeconds,
      );
    }

    // Fire call-ended callback so the chat can save history.
    final String callStatus = _callActive ? 'answered' : 'missed';
    widget.onCallEnded?.call('video', callStatus, _duration.inSeconds);

    if (_joined) {
      await _engine.leaveChannel();
      await _engine.release();
    }

    _exit();
  }

  void _exit() {
    if (widget.onEnd != null) {
      widget.onEnd!();
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  // Control methods
  Future<void> _toggleSpeaker() async {
    setState(() => _speakerOn = !_speakerOn);
    await _engine.setEnableSpeakerphone(_speakerOn);
    await _ringtonePlayer.setVolume(_speakerOn ? 1.0 : 0.8);
  }

  void _toggleMute() {
    setState(() => _micMuted = !_micMuted);
    _engine.muteLocalAudioStream(_micMuted);
  }

  void _toggleVideo() {
    setState(() => _videoEnabled = !_videoEnabled);
    _engine.muteLocalVideoStream(!_videoEnabled);
    if (_videoEnabled) {
      // Restart preview if turning video on (sometimes needed after mute)
      _engine.startPreview();
    } else {
      _engine.stopPreview();
    }
  }

  void _switchCamera() {
    setState(() => _cameraFront = !_cameraFront);
    _engine.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video fills the screen
            if (_remoteVideoView != null)
              Positioned.fill(child: _remoteVideoView!)
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Local video overlay
            if (_localVideoView != null && _videoEnabled)
              Positioned(
                top: 20,
                right: 20,
                width: 150,
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _localVideoView!,
                ),
              )
            else if (_videoEnabled)
            // Placeholder while waiting for camera
              Positioned(
                top: 20,
                right: 20,
                width: 150,
                height: 220,
                child: Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.videocam, color: Colors.white54, size: 40),
                ),
              ),

            // Bottom controls
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: _buildControls(),
            ),

            // Top status
            Positioned(
              top: 20,
              left: 20,
              child: _buildStatus(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus() {
    String title;
    String subtitle;
    switch (_callStatus) {
      case _VCallStatus.calling:
        title = 'Calling ${widget.otherUserName}…';
        subtitle = 'Connecting…';
        break;
      case _VCallStatus.ringing:
        title = 'Calling ${widget.otherUserName}…';
        subtitle = 'Ringing…';
        break;
      case _VCallStatus.connected:
        title = 'Connected with ${widget.otherUserName}';
        subtitle = _format(_duration);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final bool controlsEnabled = _callStatus != _VCallStatus.calling;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Minimize button – only shown when hosted in an overlay
          if (widget.onMinimize != null)
            IconButton(
              icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white, size: 36),
              tooltip: 'Minimize call',
              onPressed: widget.onMinimize,
            ),
          IconButton(
            icon: Icon(
              _micMuted ? Icons.mic_off : Icons.mic,
              color: controlsEnabled ? Colors.white : Colors.white30,
              size: 36,
            ),
            onPressed: controlsEnabled ? _toggleMute : null,
          ),
          IconButton(
            icon: Icon(
              _videoEnabled ? Icons.videocam : Icons.videocam_off,
              color: controlsEnabled ? Colors.white : Colors.white30,
              size: 36,
            ),
            onPressed: controlsEnabled ? _toggleVideo : null,
          ),
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red, size: 56),
            onPressed: _endCall,
          ),
          IconButton(
            icon: Icon(
              _speakerOn ? Icons.volume_up : Icons.volume_off,
              color: controlsEnabled ? Colors.white : Colors.white30,
              size: 36,
            ),
            onPressed: controlsEnabled ? _toggleSpeaker : null,
          ),
          IconButton(
            icon: Icon(
              Icons.flip_camera_android,
              color: (_videoEnabled && controlsEnabled)
                  ? Colors.white
                  : Colors.white30,
              size: 36,
            ),
            onPressed: (_videoEnabled && controlsEnabled) ? _switchCamera : null,
          ),
        ],
      ),
    );
  }

  String _format(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
   // _callTimer?.cancel();
    _timeoutTimer?.cancel();
    _ringtoneRepeatTimer?.cancel();
    _callSignalSubscription?.cancel();
    _ringtonePlayer.dispose();
    super.dispose();
  }
}