import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../providers/audio_provider.dart';
import '../../providers/timer_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../data/models/sound_model.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/atmospheric_overlay.dart';
import '../widgets/liquid_play_button.dart';
import '../widgets/tour_overlay.dart';
import '../../services/auth_service.dart';
import '../../services/ad_service.dart';
import 'info_screens.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String selectedCategory = 'All';
  final String dailyQuote = "Sleep is the best meditation.";
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Tour Keys
  final GlobalKey _timerKey = GlobalKey();
  final GlobalKey _themeKey = GlobalKey();
  final GlobalKey _categoriesKey = GlobalKey();
  final GlobalKey _controlsKey = GlobalKey();

  bool _showTour = false;

  @override
  void initState() {
    super.initState();
    _checkTourStatus();
  }

  Future<void> _checkTourStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final tourShown = prefs.getBool('tour_shown') ?? false;
    if (!tourShown) {
      setState(() => _showTour = true);
    }
  }

  Future<void> _markTourComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tour_shown', true);
    setState(() => _showTour = false);
  }

  String _getBackgroundImage() {
    switch (selectedCategory) {
      case 'Rain': return 'assets/rain_background.png';
      case 'Nature': return 'assets/nature_background.png';
      default: return 'assets/sleepie_background.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioProvider);
    final user = ref.watch(userProvider);
    final themeMode = ref.watch(themeProvider);
    final hasPremium = ref.watch(hasPremiumProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    final hasRainActive = audioState.activeSounds.any((s) => s.category == SoundCategory.rain);
    final filteredSounds = audioState.availableSounds.where((s) => 
      selectedCategory == 'All' || s.category.name.toLowerCase() == selectedCategory.toLowerCase()
    ).toList();

    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          drawer: _buildDrawer(context, isDark),
          drawerEnableOpenDragGesture: false,
          body: AtmosphericOverlay(
            showRain: hasRainActive,
            showThunder: audioState.activeSounds.any((s) => s.name.toLowerCase().contains('thunder')),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: GestureDetector(
                    onDoubleTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: AnimatedSwitcher(
                      duration: 1.seconds,
                      child: Container(
                        key: ValueKey(_getBackgroundImage()),
                        height: 380,
                        decoration: BoxDecoration(
                          image: DecorationImage(image: AssetImage(_getBackgroundImage()), fit: BoxFit.cover),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, isDark ? AppColors.bgDark : AppColors.bgLight], 
                              begin: Alignment.topCenter, 
                              end: Alignment.bottomCenter
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    key: _themeKey,
                                    onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
                                      child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white, size: 24),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const Spacer(),
                              
                              _buildCenterTimer(user, hasPremium, key: _timerKey),

                              const Spacer(),
                              
                              Text(dailyQuote, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)).animate().fadeIn().slideY(begin: 1, end: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    key: _categoriesKey,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: ['All', 'Rain', 'Nature', 'Meditation'].map((cat) {
                        bool isSelected = selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              Vibration.vibrate(duration: 50);
                              setState(() => selectedCategory = cat);
                            },
                            child: AnimatedContainer(
                              duration: 300.ms,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10)] : null,
                              ),
                              child: Text(cat, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54))),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                if (filteredSounds.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text("No sounds available yet.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white24)),
                    )),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 6 : 4, 
                        mainAxisSpacing: 20, 
                        crossAxisSpacing: 16, 
                        childAspectRatio: 0.55
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sound = filteredSounds[index];
                          final isActive = audioState.activeSounds.any((s) => s.id == sound.id);
                          final isLoading = audioState.loadingIds.contains(sound.id);
                          
                          return GestureDetector(
                            onTap: () async {
                              if (!hasPremium) {
                                _showWatchAdSheet(context);
                                return;
                              }
                              try {
                                Vibration.vibrate(duration: 30);
                                await ref.read(audioProvider.notifier).toggleSound(sound, hasPremium);
                              } catch (e) {
                                if (e.toString().contains('limit')) _showWatchAdSheet(context);
                              }
                            },
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: 400.ms,
                                  curve: Curves.easeOutBack,
                                  height: 65, width: 65,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(isActive ? 30 : 22),
                                    gradient: isActive ? AppColors.purpleGradient : null,
                                    color: isActive ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                                    border: Border.all(color: isActive ? Colors.white30 : (isDark ? Colors.white12 : Colors.black12), width: 1.5),
                                    boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 15)] : null,
                                  ),
                                  child: Center(
                                    child: isLoading
                                        ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.white70 : Colors.black54))
                                        : Icon(sound.icon, color: isActive ? Colors.white : (isDark ? Colors.white38 : Colors.black38), size: 28),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(sound.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white54 : Colors.black54))),
                              ],
                            ),
                          ).animate(target: isActive ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 300.ms);
                        },
                        childCount: filteredSounds.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 150)),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(audioState, hasPremium, isDark, key: _controlsKey),
        ),

        if (_showTour && audioState.availableSounds.isNotEmpty)
          TourOverlay(
            onComplete: _markTourComplete,
            onSkip: _markTourComplete,
            steps: [
              TourStep(
                targetKey: _timerKey,
                title: "Experience Timer",
                description: "Watch rewarded ads to earn access hours. All sounds are unlocked while you have active time.",
              ),
              TourStep(
                targetKey: _themeKey,
                title: "Dynamic Themes",
                description: "Switch between Light and Dark mode anytime to suit your environment.",
              ),
              TourStep(
                targetKey: _categoriesKey,
                title: "Immersive Sounds",
                description: "Filter and mix multiple sounds to create your perfect sleep atmosphere.",
              ),
              TourStep(
                targetKey: _controlsKey,
                title: "Master Controls",
                description: "Control the volume of each sound or set a sleep timer to automatically stop playback.",
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCenterTimer(UserState user, bool hasPremium, {Key? key}) {
    final progress = ref.watch(premiumProgressProvider);
    final hours = (user.premiumSecondsRemaining / 3600).floor();
    final mins = ((user.premiumSecondsRemaining % 3600) / 60).floor();

    String timeText = user.premiumSecondsRemaining > 0 ? "${hours}h ${mins}m" : "00:00";
    double progressValue = (progress == 0 && user.premiumSecondsRemaining > 0 ? 1 : progress);

    return Column(
      key: key,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 100, width: 100,
              child: CircularProgressIndicator(
                value: progressValue,
                strokeWidth: 6,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 28),
                Text(
                  timeText,
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          hasPremium ? "Time Active" : "No Time",
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, shadows: [const Shadow(blurRadius: 10, color: Colors.black45)]),
        ),
      ],
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: LiquidGlassCard(
        borderRadius: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Sleep Love", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text("Version 1.0.0", style: TextStyle(color: Colors.white38)),
              const SizedBox(height: 60),
              _drawerItem(Icons.info_outline_rounded, "About App", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoScreen(
                  title: "About Sleep Love",
                  backgroundImage: "assets/sleepie_background.png",
                  content: "Sleep Love is your companion for better sleep. Developed by Questra.\n\nFramework: Flutter 3.11\nLibraries: just_audio, Riverpod.\n\n© 2025 Questra.",
                )));
              }),
              _drawerItem(Icons.privacy_tip_outlined, "Privacy Policy", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoScreen(
                  title: "Privacy Policy",
                  backgroundImage: "assets/nature_background.png",
                  content: "Questra respects your privacy. Our core commitment is to provide a secure experience.\n\nData Collection: Any audio processing happens entirely on your device.\n\nLocal Storage: Audio files are cached locally for offline playback.",
                )));
              }),
              const Spacer(),
              _drawerItem(Icons.logout_rounded, "Logout", () => AuthService().logout(), color: Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color color = Colors.white70}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Widget _buildBottomBar(AudioState state, bool hasPremium, bool isDark, {Key? key}) {
    if (state.activeSounds.isEmpty) return const SizedBox.shrink();
    return LiquidGlassCard(
      key: key,
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      borderRadius: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: Icon(Icons.timer_outlined, color: isDark ? Colors.white70 : Colors.black54), onPressed: () => _showTimerSheet(context, hasPremium)),
          LiquidPlayButton(isPlaying: true, onTap: () => ref.read(audioProvider.notifier).stopAll()),
          IconButton(icon: Icon(Icons.tune_rounded, color: isDark ? Colors.white70 : Colors.black54), onPressed: () => _showMixerSheet(context, state, hasPremium)),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutBack);
  }

  void _showTimerSheet(BuildContext context, bool hasPremium) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: AppColors.bgDark, borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Sleep Timer", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16, runSpacing: 16,
              children: [15, 30, 60, 120, 480].map((mins) {
                return GestureDetector(
                  onTap: () { ref.read(timerProvider.notifier).setTimer(mins); Navigator.pop(context); },
                  child: Container(
                    width: 100, padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(child: Text("${mins >= 60 ? (mins/60).floor() : mins}${mins >= 60 ? 'h' : 'm'}", style: const TextStyle(color: Colors.white))),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showMixerSheet(BuildContext context, AudioState state, bool hasPremium) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (c, s) => Container(
            decoration: BoxDecoration(color: AppColors.bgDark, borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                Text("Liquid Mixer", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    controller: s,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: state.activeSounds.length,
                    itemBuilder: (c, i) {
                      final sound = state.activeSounds[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: LiquidGlassCard(
                          padding: const EdgeInsets.all(12),
                          borderRadius: 20,
                          child: Row(
                            children: [
                              Icon(sound.icon, color: AppColors.primary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(sound.name, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Slider(
                                  value: sound.volume, 
                                  activeColor: AppColors.primary, 
                                  inactiveColor: Colors.white10, 
                                  onChanged: (v) {
                                    setSheetState(() {
                                      sound.volume = v;
                                    });
                                    ref.read(audioProvider.notifier).updateVolume(sound.id, v);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.1, end: 0);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWatchAdSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Unlock Everything", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Text("Watch a short ad to earn 1 hour of premium access to all sounds and features.", textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white70)),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                AdService().showRewarded(
                  onRewardEarned: () {
                    ref.read(userProvider.notifier).watchAdAndEarnHour();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Premium access granted for 1 hour!")));
                  },
                  onFailed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ad not ready. Please try again in a moment.")));
                  }
                );
                Navigator.pop(context);
              },
              child: Container(
                height: 60, width: double.infinity,
                decoration: BoxDecoration(gradient: AppColors.purpleGradient, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20)]),
                child: const Center(child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Text("Watch Ad for 1 Hour", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                )),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
