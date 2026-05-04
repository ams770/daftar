import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playScanSound() async {
    try {
      await _player.play(AssetSource('sounds/scanner.mp3'));
    } catch (e) {
      // Ignore errors in sound playing
    }
  }

  static void dispose() {
    _player.dispose();
  }
}
