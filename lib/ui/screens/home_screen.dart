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
import '../../services/download_service.dart';
import 'info_screens.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String selectedCategory = 'All';
  final String dailyQuote = "Sleep is the best meditation.";
  final DownloadService _downloadService = DownloadService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Tour Keys
  final GlobalKey _proStatusKey = GlobalKey();
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
          body: AtmosphericOverlay(
            showRain: hasRainActive,
            showThunder: audioState.activeSounds.any((s) => s.name.toLowerCase().contains('thunder')),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration: 1.seconds,
                    child: Container(
                      key: ValueKey(_getBackgroundImage()),
                      height: 320,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Top Left: Pro Status Indicator (Hamburger removed as requested)
                                GestureDetector(
                                  key: _proStatusKey,
                                  onTap: () => hasPremium ? null : _showUpgradeSheet(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: hasPremium ? AppColors.accent.withOpacity(0.2) : Colors.white10, 
                                      borderRadius: BorderRadius.circular(20), 
                                      border: Border.all(color: hasPremium ? AppColors.accent : Colors.white24)
                                    ),
                                    child: Row(children: [
                                      Icon(Icons.star_rounded, size: 16, color: hasPremium ? AppColors.accent : Colors.amber), 
                                      const SizedBox(width: 8), 
                                      Text(hasPremium ? "Pro Activated" : "Get Pro", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))
                                    ]),
                                  ),
                                ).animate(target: hasPremium ? 1 : 0).shimmer(duration: 2.seconds),
                                
                                if (!user.isPro)
                                  _buildPremiumProgressBar(user, key: _timerKey),

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
                            Text(dailyQuote, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)).animate().fadeIn().slideY(begin: 1, end: 0),
                          ],
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
                                color: isSelected ? AppColors.primary : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10)] : null,
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
                              if (!sound.isFree && !hasPremium) {
                                _showUpgradeSheet(context);
                                return;
                              }
                              try {
                                Vibration.vibrate(duration: 30);
                                await ref.read(audioProvider.notifier).toggleSound(sound, hasPremium);
                              } catch (e) {
                                if (e.toString().contains('limit')) _showUpgradeSheet(context);
                              }
                            },
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    AnimatedContainer(
                                      duration: 400.ms,
                                      curve: Curves.easeOutBack,
                                      height: 65, width: 65,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(isActive ? 30 : 22),
                                        gradient: isActive ? AppColors.purpleGradient : null,
                                        color: isActive ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                                        border: Border.all(color: isActive ? Colors.white30 : (isDark ? Colors.white12 : Colors.black12), width: 1.5),
                                        boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 15)] : null,
                                      ),
                                      child: Center(
                                        child: isLoading
                                            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.white70 : Colors.black54))
                                            : Icon(sound.icon, color: isActive ? Colors.white : (isDark ? Colors.white38 : Colors.black38), size: 28),
                                      ),
                                    ),
                                    if (!sound.isFree && !hasPremium)
                                      const Positioned(right: 4, top: 4, child: Icon(Icons.lock_rounded, size: 14, color: Colors.amber)),
                                  ],
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

        // Tour Overlay
        if (_showTour && audioState.availableSounds.isNotEmpty)
          TourOverlay(
            onComplete: _markTourComplete,
            onSkip: _markTourComplete,
            steps: [
              TourStep(
                targetKey: _proStatusKey,
                title: "Premium Access",
                description: "View your current status and unlock unlimited sounds. Swipe from the right edge anytime to open the main menu.",
              ),
              TourStep(
                targetKey: _timerKey,
                title: "Premium Timer",
                description: "Watch ads to earn premium access hours. This bar shows your remaining premium time.",
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

  Widget _buildPremiumProgressBar(UserState user, {Key? key}) {
    final progress = ref.watch(premiumProgressProvider);
    final hours = (user.premiumSecondsRemaining / 3600).floor();
    final mins = ((user.premiumSecondsRemaining % 3600) / 60).floor();

    return Column(
      key: key,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 40, width: 40,
              child: CircularProgressIndicator(
                value: progress == 0 && user.premiumSecondsRemaining > 0 ? 1 : progress,
                strokeWidth: 3,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
            Icon(Icons.bolt_rounded, color: user.premiumSecondsRemaining > 0 ? AppColors.accent : Colors.white24, size: 20),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          user.premiumSecondsRemaining > 0 ? "${hours}h ${mins}m" : "No Premium",
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
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
                  content: "Sleep Love is your premium companion for better sleep and deep meditation. Developed by Questra, this application leverages the power of atmospheric soundscapes to enhance your sleep quality.\n\nFramework: Flutter 3.11\nLibraries: just_audio, Riverpod, flutter_animate, Dio, Firebase.\n\n© 2025 Questra. All rights reserved.",
                )));
              }),
              _drawerItem(Icons.privacy_tip_outlined, "Privacy Policy", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoScreen(
                  title: "Privacy Policy",
                  backgroundImage: "assets/nature_background.png",
                  content: "Questra respects your privacy. Our core commitment is to provide a secure and serene experience.\n\n1. Data Collection: We do not collect or record your ambient sounds. Any audio processing happens entirely on your device.\n\n2. Firebase Sync: We use Firebase to synchronize your Pro status across devices. This requires a unique identifier but no personal contact data unless you explicitly sign in.\n\n3. Local Storage: Audio files are cached locally for offline playback to save your bandwidth.\n\n4. Analytics: We may use anonymous usage data to improve sound quality and app performance.\n\nFor any inquiries regarding your data, contact privacy@questra.com.",
                )));
              }),
              _drawerItem(Icons.star_outline_rounded, "Rate Us", () {}),
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
                bool locked = !hasPremium && mins > 30;
                return GestureDetector(
                  onTap: locked ? () => _showUpgradeSheet(context) : () { ref.read(timerProvider.notifier).setTimer(mins); Navigator.pop(context); },
                  child: Container(
                    width: 100, padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: locked ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: locked ? Colors.white10 : Colors.white24),
                    ),
                    child: Center(child: Text("${mins >= 60 ? (mins/60).floor() : mins}${mins >= 60 ? 'h' : 'm'} ${locked ? '🔒' : ''}", style: const TextStyle(color: Colors.white))),
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
      builder: (context) => DraggableScrollableSheet(
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
              const SizedBox(height: 8),
              if (!hasPremium) Text("Limit: 2 Sounds Active", style: TextStyle(color: AppColors.primary, fontSize: 12)),
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
                        padding: const EdgeInsets.all(16),
                        borderRadius: 20,
                        child: Row(
                          children: [
                            Icon(sound.icon, color: AppColors.primary),
                            const SizedBox(width: 16),
                            Expanded(child: Text(sound.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white))),
                            SizedBox(width: 150, child: Slider(value: sound.volume, activeColor: AppColors.primary, inactiveColor: Colors.white10, onChanged: (v) => ref.read(audioProvider.notifier).updateVolume(sound.id, v))),
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
    );
  }

  void _showUpgradeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Premium Experience", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            _buildProFeature("Unlimited Sounds Mixing", Icons.tune),
            _buildProFeature("High Fidelity Audio", Icons.high_quality),
            _buildProFeature("Offline Downloads", Icons.download_done_rounded),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                AdService.showInterstitial();
                ref.read(userProvider.notifier).upgradeToPro();
                Navigator.pop(context);
              },
              child: Container(
                height: 60, width: double.infinity,
                decoration: BoxDecoration(gradient: AppColors.purpleGradient, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20)]),
                child: const Center(child: Text("Upgrade to Pro - \$4.99/mo", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                AdService.showRewarded(() {
                  ref.read(userProvider.notifier).watchAdAndEarnHour();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Premium access granted for 1 hour!")));
                });
                Navigator.pop(context);
              },
              child: const Text("Watch Ad for 1 Hour Premium", style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProFeature(String text, IconData icon) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Icon(icon, size: 20, color: AppColors.primary), const SizedBox(width: 12), Text(text, style: const TextStyle(color: Colors.white70))]));
  }
}
