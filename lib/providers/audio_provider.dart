import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/sound_model.dart';
import '../data/repositories/audio_repository.dart';
import '../services/notification_service.dart';
import 'user_provider.dart';

class AudioState {
  final List<SoundModel> availableSounds;
  final List<SoundModel> activeSounds;
  final Set<String> loadingIds;
  final double setupProgress;
  final bool isSetupComplete;
  final bool isPremiumSetupNeeded;

  AudioState({
    required this.availableSounds,
    required this.activeSounds,
    this.loadingIds = const {},
    this.setupProgress = 0,
    this.isSetupComplete = false,
    this.isPremiumSetupNeeded = false,
  });

  AudioState copyWith({
    List<SoundModel>? availableSounds,
    List<SoundModel>? activeSounds,
    Set<String>? loadingIds,
    double? setupProgress,
    bool? isSetupComplete,
    bool? isPremiumSetupNeeded,
  }) {
    return AudioState(
      availableSounds: availableSounds ?? this.availableSounds,
      activeSounds: activeSounds ?? this.activeSounds,
      loadingIds: loadingIds ?? this.loadingIds,
      setupProgress: setupProgress ?? this.setupProgress,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
      isPremiumSetupNeeded: isPremiumSetupNeeded ?? this.isPremiumSetupNeeded,
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
        _checkIfPremiumSetupNeeded();
      }
    });
  }

  void _checkIfPremiumSetupNeeded() async {
    final hasPremium = ref.read(hasPremiumProvider);
    if (hasPremium) {
      final prefs = await SharedPreferences.getInstance();
      final user = ref.read(userProvider);
      final proComplete = prefs.getBool('pro_setup_complete_${user.uid}') ?? false;
      if (!proComplete) {
        state = state.copyWith(isPremiumSetupNeeded: true);
      }
    }
  }

  Future<void> startInitialSetup({bool forPremium = false}) async {
    final targets = forPremium 
        ? state.availableSounds.where((s) => !s.isFree).toList()
        : state.availableSounds.where((s) => s.isFree).toList();
        
    if (targets.isEmpty) return;

    for (int i = 0; i < targets.length; i++) {
      final sound = targets[i];
      state = state.copyWith(
        loadingIds: {...state.loadingIds, sound.id}, 
        setupProgress: (i + 1) / targets.length
      );
      
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        NotificationService.showProgress(i + 1, targets.length);
      }

      await _repository.cacheOnly(sound); 
      state = state.copyWith(loadingIds: state.loadingIds.where((id) => id != sound.id).toSet());
    }

    final prefs = await SharedPreferences.getInstance();
    if (forPremium) {
      final user = ref.read(userProvider);
      await prefs.setBool('pro_setup_complete_${user.uid}', true);
      state = state.copyWith(isPremiumSetupNeeded: false, setupProgress: 1.0);
    } else {
      await prefs.setBool('setup_complete', true);
      state = state.copyWith(isSetupComplete: true, setupProgress: 1.0);
    }
    
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

  Future<void> toggleSound(SoundModel sound, bool hasPremium) async {
    final isActive = state.activeSounds.any((s) => s.id == sound.id);
    
    if (isActive) {
      _repository.stopSound(sound.id);
      state = state.copyWith(
        activeSounds: state.activeSounds.where((s) => s.id != sound.id).toList(),
      );
    } else {
      // Limit removed for all users with active time
      if (!hasPremium && state.activeSounds.length >= 1) {
        throw 'Time expired. Watch an ad to continue mixing.';
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
