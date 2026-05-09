import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../models/sound_model.dart';

class AudioRepository {
  final Map<String, AudioPlayer> _players = {};
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<String> _getCachePath(String id) async {
    final cacheDir = await getTemporaryDirectory();
    return "${cacheDir.path}/$id.wav";
  }

  Future<bool> cacheOnly(SoundModel sound, {int retries = 3}) async {
    final path = await _getCachePath(sound.id);
    final file = File(path);
    if (await file.exists() && await file.length() > 0) return true;

    for (int i = 0; i < retries; i++) {
      try {
        await _dio.download(sound.remoteUrl, path);
        return true;
      } catch (e) {
        if (await file.exists()) await file.delete();
        if (i == retries - 1) return false;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return false;
  }

  Future<void> playSound(SoundModel sound) async {
    if (_players.containsKey(sound.id)) return;

    final player = AudioPlayer();
    _players[sound.id] = player;

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      String? playPath;

      if (sound.localPath != null && await File(sound.localPath!).exists()) {
        playPath = sound.localPath;
      } else {
        final cachePath = await _getCachePath(sound.id);
        final cached = await cacheOnly(sound);
        if (cached) playPath = cachePath;
      }

      if (playPath != null) {
        // Use AudioSource for gapless looping support
        await player.setAudioSource(
          AudioSource.uri(Uri.file(playPath)),
          preload: true,
        );
        
        await player.setLoopMode(LoopMode.one);
        
        // Soft Fade In
        await player.setVolume(0);
        player.play();
        _fadeIn(player, sound.volume);
      }
    } catch (e) {
      print("Error playing sound (${sound.name}): $e");
      stopSound(sound.id);
    }
  }

  void _fadeIn(AudioPlayer player, double targetVolume) async {
    double currentVol = 0;
    while (currentVol < targetVolume) {
      currentVol += 0.05;
      if (currentVol > targetVolume) currentVol = targetVolume;
      await player.setVolume(currentVol);
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void stopSound(String id) {
    if (_players.containsKey(id)) {
      _players[id]?.stop();
      _players[id]?.dispose();
      _players.remove(id);
    }
  }

  void updateVolume(String id, double volume) {
    _players[id]?.setVolume(volume);
  }

  void stopAll() {
    for (var player in _players.values) {
      player.stop();
      player.dispose();
    }
    _players.clear();
  }
}
