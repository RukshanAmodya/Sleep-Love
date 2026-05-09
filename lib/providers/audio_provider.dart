import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/sound_model.dart';
import '../data/repositories/audio_repository.dart';
import '../services/notification_service.dart';

class AudioState {
  final List<SoundModel> availableSounds;
  final List<SoundModel> activeSounds;
  final Set<String> loadingIds;
  final double setupProgress;
  final bool isSetupComplete;

  AudioState({
    required this.availableSounds,
    required this.activeSounds,
    this.loadingIds = const {},
    this.setupProgress = 0,
    this.isSetupComplete = false,
  });

  AudioState copyWith({
    List<SoundModel>? availableSounds,
    List<SoundModel>? activeSounds,
    Set<String>? loadingIds,
    double? setupProgress,
    bool? isSetupComplete,
  }) {
    return AudioState(
      availableSounds: availableSounds ?? this.availableSounds,
      activeSounds: activeSounds ?? this.activeSounds,
      loadingIds: loadingIds ?? this.loadingIds,
      setupProgress: setupProgress ?? this.setupProgress,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
    );
  }
}

class AudioNotifier extends Notifier<AudioState> {
  final AudioRepository _repository = AudioRepository();
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  @override
  AudioState build() {
    _listenToSounds();
    _checkSetupStatus();
    return AudioState(availableSounds: [], activeSounds: []);
  }

  Future<void> _checkSetupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final complete = prefs.getBool('setup_complete') ?? false;
    state = state.copyWith(isSetupComplete: complete);
  }

  void _listenToSounds() {
    _db.ref('sounds').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final List<SoundModel> sounds = [];
        data.forEach((key, value) {
          final s = value as Map;
          sounds.add(SoundModel(
            id: key,
            name: s['name'] ?? 'Unknown',
            remoteUrl: s['remoteUrl'] ?? '',
            icon: _getIconData(s['icon']),
            category: _getCategory(s['category']),
            isFree: s['isFree'] ?? true,
          ));
        });
        state = state.copyWith(availableSounds: sounds);
      }
    });
  }

  Future<void> startInitialSetup() async {
    final freeSounds = state.availableSounds.where((s) => s.isFree).toList();
    if (freeSounds.isEmpty) return;

    for (int i = 0; i < freeSounds.length; i++) {
      final sound = freeSounds[i];
      state = state.copyWith(loadingIds: {...state.loadingIds, sound.id}, setupProgress: (i + 1) / freeSounds.length);
      
      // Update Notification if backgrounded
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        NotificationService.showProgress(i + 1, freeSounds.length);
      }

      await _repository.cacheOnly(sound); 
      state = state.copyWith(loadingIds: state.loadingIds.where((id) => id != sound.id).toSet());
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);
    state = state.copyWith(isSetupComplete: true, setupProgress: 1.0);
    
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      NotificationService.showComplete();
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'cloudy_snowing': return Icons.cloudy_snowing;
      case 'nature': return Icons.nature_people_rounded;
      case 'spa': return Icons.spa_rounded;
      default: return Icons.music_note_rounded;
    }
  }

  SoundCategory _getCategory(String? cat) {
    switch (cat) {
      case 'rain': return SoundCategory.rain;
      case 'nature': return SoundCategory.nature;
      case 'meditation': return SoundCategory.meditation;
      default: return SoundCategory.nature;
    }
  }

  Future<void> toggleSound(SoundModel sound, bool isPro) async {
    final isActive = state.activeSounds.any((s) => s.id == sound.id);
    
    if (isActive) {
      // Toggle OFF
      _repository.stopSound(sound.id);
      state = state.copyWith(
        activeSounds: state.activeSounds.where((s) => s.id != sound.id).toList(),
      );
    } else {
      // Toggle ON
      // Check Free Limit
      if (!isPro && state.activeSounds.length >= 2) {
        throw 'Free limit reached'; // Handled in UI
      }

      state = state.copyWith(loadingIds: {...state.loadingIds, sound.id});
      await _repository.playSound(sound);
      state = state.copyWith(
        loadingIds: state.loadingIds.where((id) => id != sound.id).toSet(),
        activeSounds: [...state.activeSounds, sound],
      );
    }
  }

  void updateVolume(String id, double volume) {
    _repository.updateVolume(id, volume);
    state = state.copyWith(
      activeSounds: state.activeSounds.map((s) {
        if (s.id == id) s.volume = volume;
        return s;
      }).toList(),
    );
  }

  void stopAll() {
    _repository.stopAll();
    state = state.copyWith(activeSounds: [], loadingIds: {});
  }
}

final audioProvider = NotifierProvider<AudioNotifier, AudioState>(AudioNotifier.new);
