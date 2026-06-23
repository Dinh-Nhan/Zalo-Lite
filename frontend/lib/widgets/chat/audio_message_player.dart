import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final int? durationSeconds;
  final bool isMine;

  const AudioMessagePlayer({
    super.key,
    required this.audioUrl,
    this.durationSeconds,
    required this.isMine,
  });

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  late final AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  StreamSubscription? _stateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _completeSubscription;

  @override
  void initState() {
    super.initState();
    debugPrint('[AudioMessagePlayer] initState called for URL: ${widget.audioUrl}');
    _audioPlayer = AudioPlayer();
    
    // Đảm bảo âm thanh phát ra loa ngoài (speaker) thay vì loa thoại (earpiece)
    _audioPlayer.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      ),
    );

    // Set initial duration if provided by message model
    if (widget.durationSeconds != null) {
      _duration = Duration(seconds: widget.durationSeconds!);
    }

    _initPlayerListeners();
  }

  void _initPlayerListeners() {
    _stateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      debugPrint('[AudioMessagePlayer] State changed to: $state');
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((dur) {
      debugPrint('[AudioMessagePlayer] Duration loaded: $dur');
      if (mounted) {
        setState(() {
          _duration = dur;
        });
      }
    });

    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      debugPrint('[AudioMessagePlayer] Playback completed');
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _playerState = PlayerState.stopped;
        });
      }
    });
  }

  Future<void> _playPause() async {
    debugPrint('[AudioMessagePlayer] _playPause clicked. Current state: $_playerState');
    try {
      if (_playerState == PlayerState.playing) {
        debugPrint('[AudioMessagePlayer] Pausing audio player');
        await _audioPlayer.pause();
      } else {
        debugPrint('[AudioMessagePlayer] Playing audio source: ${widget.audioUrl}');
        await _audioPlayer.play(UrlSource(widget.audioUrl));
      }
    } catch (e) {
      debugPrint('[AudioMessagePlayer] Playback error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể phát âm thanh: $e')),
        );
      }
    }
  }

  Future<void> _seek(double value) async {
    final targetPosition = Duration(milliseconds: value.toInt());
    debugPrint('[AudioMessagePlayer] Seeking to: $targetPosition');
    await _audioPlayer.seek(targetPosition);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    debugPrint('[AudioMessagePlayer] dispose called for URL: ${widget.audioUrl}');
    _stateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlaying = _playerState == PlayerState.playing;
    final Color primaryColor = widget.isMine ? Colors.white : const Color(0xFF0068FF);
    final Color secondaryColor = widget.isMine ? Colors.white70 : Colors.black87;
    final Color sliderActiveColor = widget.isMine ? Colors.white : const Color(0xFF0068FF);
    final Color sliderInactiveColor = widget.isMine ? Colors.white30 : Colors.grey.shade300;

    double maxDurationMs = _duration.inMilliseconds.toDouble();
    if (maxDurationMs <= 0) {
      maxDurationMs = 1000.0; // Avoid slider exception when duration is 0
    }
    final double currentPositionMs = _position.inMilliseconds.toDouble().clamp(0.0, maxDurationMs);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play / Pause Button
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: primaryColor,
              size: 36,
            ),
            onPressed: _playPause,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          
          // Slider and Timer
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                height: 20,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                    activeTrackColor: sliderActiveColor,
                    inactiveTrackColor: sliderInactiveColor,
                    thumbColor: sliderActiveColor,
                    overlayColor: sliderActiveColor.withOpacity(0.2),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: maxDurationMs,
                    value: currentPositionMs,
                    onChanged: (val) => _seek(val),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: secondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
