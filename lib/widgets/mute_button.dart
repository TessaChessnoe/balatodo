import 'package:flutter/material.dart';
import '../main.dart'; // for access to musicPlayer

class MuteButton extends StatefulWidget {
  final bool alignEnd; // true for end of tray, false for centered

  const MuteButton({super.key, this.alignEnd = false});

  @override
  State<MuteButton> createState() => _MuteButtonState();
}

class _MuteButtonState extends State<MuteButton> {
  bool isMuted = musicPlayer.isMuted;

  void _toggleMute() async {
    setState(() {
      isMuted = !isMuted;
      musicPlayer.isMuted = isMuted;
      musicPlayer.setVolume(isMuted ? 0.0 : 1.0);
    });
    await musicPlayer.updateMute(isMuted); // ✅ saves + sets volume
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _toggleMute,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.all(12),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Icon(
        isMuted ? Icons.music_off : Icons.music_note,
        color: Colors.white,
        size: 45,
      ),
    );
  }
}
