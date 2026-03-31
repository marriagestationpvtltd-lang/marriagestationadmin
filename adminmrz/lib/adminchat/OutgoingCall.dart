import 'dart:async';
import 'dart:math';
import 'package:adminmrz/adminchat/services/pushservice.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'tokengenerator.dart';

class CallScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String otherUserId;
  final String otherUserName;
  final bool isOutgoingCall;
  final VoidCallback? onMinimize;
  final VoidCallback? onEnd;
  /// Called when the call ends with (callType, status, durationSeconds).
  /// callType is always 'audio'. status is 'answered' or 'missed'.
  final void Function(String callType, String status, int durationSeconds)? onCallEnded;

  const CallScreen({
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
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late RtcEngine _engine;

  int _localUid = 0;
  int? _remoteUid;

  String _channel = '';
  String _token = '';

  bool _callActive = false;
  bool _micMuted = false;
  bool _speakerOn = true;
  bool _ending = false;
  bool _isCallRinging = true;

  Timer? _timeoutTimer;
  Timer? _callTimer;
  Duration _duration = Duration.zero;

  late AudioPlayer _ringtonePlayer;
  bool _isPlayingRingtone = false;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _ringtonePlayer = AudioPlayer();
    _setupAudio();
    _startCall();
  }

  // ================= AUDIO =================
  void _setupAudio() {
    _ringtonePlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlayingRingtone = state == PlayerState.playing);
    });
  }

  Future<void> _playRingtone() async {
    if (!widget.isOutgoingCall) return;

    try {
      await _ringtonePlayer.stop();

      await _ringtonePlayer.play(
        AssetSource('images/outcall.mp3'),
        volume: 1.0,
      );

      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
    }
  }

  Future<void> _stopRingtone() async {
    try {
      await _ringtonePlayer.stop();
      if (mounted) setState(() => _isPlayingRingtone = false);
    } catch (e) {
    }
  }

  // ================= START CALL =================
  Future<void> _startCall() async {
    try {
      if (widget.isOutgoingCall) {
        await _playRingtone();
      }

      _localUid = Random().nextInt(999999);

      _channel =
      'call_${widget.currentUserId}_${widget.otherUserId}_${DateTime.now().millisecondsSinceEpoch}';

      _token = await AgoraTokenService.getToken(
        channelName: _channel,
        uid: _localUid,
      );

      if (widget.isOutgoingCall) {
        await NotificationService.sendCallNotification(
          recipientUserId: widget.otherUserId,
          callerName: widget.currentUserName,
          channelName: _channel,
          callerId: widget.currentUserId,
          callerUid: _localUid.toString(),
          agoraAppId: AgoraTokenService.appId,
          agoraCertificate: 'SERVER_ONLY',
        );
      }

      // ================= AGORA =================
      _engine = createAgoraRtcEngine();

      await _engine.initialize(RtcEngineContext(
        appId: AgoraTokenService.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onUserJoined: (_, uid, __) async {
            if (!mounted) return;


            setState(() {
              _remoteUid = uid;
              _isCallRinging = false;
              _callActive = true;
            });

            await _stopRingtone();
            _startTimer();
          },

          onUserOffline: (_, __, ___) async {

            if (!_ending) {
              await _endCall();
            }
          },

          onError: (code, msg) {
          },
        ),
      );

      await _engine.enableAudio();

      await _engine.joinChannel(
        token: _token,
        channelId: _channel,
        uid: _localUid,
        options: const ChannelMediaOptions(
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );

      // ================= TIMEOUT =================
      _timeoutTimer = Timer(const Duration(seconds: 30), () async {
        if (_remoteUid == null && !_ending) {
          await NotificationService.sendMissedCallNotification(
            callerId: widget.currentUserId,
            callerName: widget.currentUserName,
          );

          await _endCall();
        }
      });
    } catch (e) {
      _exit();
    }
  }

  // ================= TIMER =================
  void _startTimer() {
    _timeoutTimer?.cancel();

    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _duration += const Duration(seconds: 1));
      }
    });
  }

  // ================= END CALL =================
  Future<void> _endCall() async {
    if (_ending) return;
    _ending = true;

    try {
      _callTimer?.cancel();
      _timeoutTimer?.cancel();

      await _stopRingtone();

      await _engine.leaveChannel();

      // 🔥 IMPORTANT: give time for Agora (web fix)
      await Future.delayed(const Duration(milliseconds: 300));

      await _engine.release();
    } catch (e) {
    }

    // Fire call-ended callback so the chat can save history.
    final String callStatus = _callActive ? 'answered' : 'missed';
    widget.onCallEnded?.call('audio', callStatus, _duration.inSeconds);

    if (!mounted) return;

    _exit();
  }

  void _exit() {
    if (widget.onEnd != null) {
      widget.onEnd!();
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _callActive ? Icons.phone_in_talk : Icons.phone,
              color: Colors.white,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              _callActive
                  ? 'Connected with ${widget.otherUserName}'
                  : 'Calling ${widget.otherUserName}...',
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              _callActive ? _format(_duration) : 'Ringing...',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),

            // ================= BUTTONS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.onMinimize != null) ...[
                  IconButton(
                    icon: const Icon(Icons.picture_in_picture_alt,
                        color: Colors.white, size: 36),
                    tooltip: 'Minimize call',
                    onPressed: widget.onMinimize,
                  ),
                  const SizedBox(width: 24),
                ],
                IconButton(
                  icon: const Icon(Icons.call_end,
                      color: Colors.red, size: 56),
                  onPressed: _endCall,
                ),
              ],
            ),

            if (_isPlayingRingtone)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text("Ringing...",
                    style: TextStyle(color: Colors.green)),
              ),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  // ================= DISPOSE =================
  @override
  void dispose() {
    _callTimer?.cancel();
    _timeoutTimer?.cancel();

    try {
      _engine.leaveChannel();
      _engine.release();
    } catch (_) {}

    _ringtonePlayer.dispose();
    super.dispose();
  }
}