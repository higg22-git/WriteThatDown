import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/provider_config.dart';
import '../../models/provider_type.dart';
import '../../providers.dart';
import 'app_shell.dart';

// ─────────────────────────────────────────────
// Per-provider onboarding metadata
// ─────────────────────────────────────────────

class _ProviderGuide {
  const _ProviderGuide({
    required this.type,
    required this.tagline,
    required this.costNote,
    required this.signUpUrl,
    required this.keyDashboardUrl,
    required this.steps,
    required this.keyPrefix,
    required this.keyHint,
  });

  final ProviderType type;
  final String tagline;
  final String costNote;
  final String signUpUrl;
  final String keyDashboardUrl;
  final List<String> steps;
  final String keyPrefix;
  final String keyHint;
}

const _providerGuides = <ProviderType, _ProviderGuide>{
  ProviderType.openai: _ProviderGuide(
    type: ProviderType.openai,
    tagline: 'Reliable quality. Great default choice.',
    costNote: 'gpt-4.1-mini is fast and inexpensive. Only pay for what you use.',
    signUpUrl: 'https://platform.openai.com/signup',
    keyDashboardUrl: 'https://platform.openai.com/api-keys',
    keyPrefix: 'sk-',
    keyHint: 'Starts with sk-…',
    steps: [
      'Go to platform.openai.com/signup and create an account (or log in).',
      'In the top menu, click your avatar → API keys.',
      'Click "Create new secret key", give it any name, then click "Create".',
      'Copy the key — it starts with sk- and is only shown once.',
      'Paste it in the field below.',
    ],
  ),
  ProviderType.anthropic: _ProviderGuide(
    type: ProviderType.anthropic,
    tagline: 'Strong at reasoning and following complex instructions.',
    costNote: 'claude-3-5-haiku is the low-cost option in the Anthropic lineup.',
    signUpUrl: 'https://console.anthropic.com',
    keyDashboardUrl: 'https://console.anthropic.com/settings/keys',
    keyPrefix: 'sk-ant-',
    keyHint: 'Starts with sk-ant-…',
    steps: [
      'Go to console.anthropic.com and sign up or log in.',
      'Click "Get API Keys" in the left sidebar, or go to Settings → API Keys.',
      'Click "Create Key", give it a name, and confirm.',
      'Copy the key — it starts with sk-ant- and is shown only once.',
      'Paste it in the field below.',
    ],
  ),
  ProviderType.google: _ProviderGuide(
    type: ProviderType.google,
    tagline: 'Fast and generous free tier to start.',
    costNote: 'Gemini Flash is very affordable and has a free tier.',
    signUpUrl: 'https://aistudio.google.com',
    keyDashboardUrl: 'https://aistudio.google.com/app/apikey',
    keyPrefix: 'AIza',
    keyHint: 'Starts with AIza…',
    steps: [
      'Go to aistudio.google.com and sign in with your Google account.',
      'Click "Get API key" in the left sidebar.',
      'Click "Create API key" and choose a Google Cloud project (or create one).',
      'Copy the generated key — it starts with AIza.',
      'Paste it in the field below.',
    ],
  ),
  ProviderType.groq: _ProviderGuide(
    type: ProviderType.groq,
    tagline: 'Ultra-fast inference. Great for snappy voice replies.',
    costNote: 'Groq has a generous free tier and very low paid rates.',
    signUpUrl: 'https://console.groq.com',
    keyDashboardUrl: 'https://console.groq.com/keys',
    keyPrefix: 'gsk_',
    keyHint: 'Starts with gsk_…',
    steps: [
      'Go to console.groq.com and sign up or log in.',
      'In the left sidebar, click "API Keys".',
      'Click "Create API Key", give it a name, then click "Submit".',
      'Copy the key — it starts with gsk_ and is shown only once.',
      'Paste it in the field below.',
    ],
  ),
};

// ─────────────────────────────────────────────
// Onboarding screen
// ─────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  ProviderType _selectedProvider = ProviderType.openai;
  final _apiKeyController = TextEditingController();
  bool _keyObscured = true;
  bool _isSaving = false;
  String? _keyError;

  static const _totalSteps = 4; // 0=welcome 1=pick 2=instructions 3=paste

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  _ProviderGuide get _guide => _providerGuides[_selectedProvider]!;

  Future<void> _advance() async {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _finishSetup();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _keyError = null;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finishSetup() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      setState(() => _keyError = 'Please paste your API key before continuing.');
      return;
    }

    // Soft prefix check — warn but don't block, provider may update their format
    final expectedPrefix = _guide.keyPrefix;
    if (!key.startsWith(expectedPrefix)) {
      setState(() => _keyError =
          'That key doesn\'t look right — ${_guide.type.displayName} keys should start with "$expectedPrefix". Double-check you copied the full key.');
      return;
    }

    setState(() {
      _isSaving = true;
      _keyError = null;
    });

    // Verify the key with a real API call before saving.
    final verifyError = await ref.read(llmGatewayProvider).testConnection(
          _selectedProvider,
          key,
        );

    if (!mounted) return;

    if (verifyError != null) {
      setState(() {
        _isSaving = false;
        _keyError = verifyError;
      });
      return;
    }

    final config = ProviderConfig.defaults(_selectedProvider).copyWith(
      isEnabled: true,
      isVerified: true,
    );

    await ref.read(settingsControllerProvider).saveAll(
          selectedChatProvider: _selectedProvider,
          selectedExtractionProvider: _selectedProvider,
          providerConfigs: {
            for (final type in ProviderType.values)
              type: type == _selectedProvider
                  ? config
                  : ProviderConfig.defaults(type),
          },
          pendingApiKeys: {
            _selectedProvider: key,
          },
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ref.read(settingsControllerProvider).error != null) {
      setState(() => _keyError = ref.read(settingsControllerProvider).error);
      return;
    }

    // Mark onboarding complete then push the main shell
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5E8C8), Color(0xFFF0EBE0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _StepIndicator(current: _currentStep, total: _totalSteps),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _WelcomePage(onNext: _advance),
                    _PickProviderPage(
                      selected: _selectedProvider,
                      onSelect: (p) => setState(() => _selectedProvider = p),
                      onNext: _advance,
                    ),
                    _InstructionsPage(
                      guide: _guide,
                      onNext: _advance,
                      onBack: _back,
                    ),
                    _PasteKeyPage(
                      guide: _guide,
                      controller: _apiKeyController,
                      obscured: _keyObscured,
                      onToggleObscure: () =>
                          setState(() => _keyObscured = !_keyObscured),
                      isSaving: _isSaving,
                      error: _keyError,
                      onBack: _back,
                      onFinish: _finishSetup,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step indicator
// ─────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (index) {
          final active = index == current;
          final done = index < current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: active ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: done || active
                  ? const Color(0xFF174C4F)
                  : const Color(0xFFCFC5B0),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared layout wrapper
// ─────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.child,
    this.scrollable = false,
  });

  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: child,
    );
    return scrollable ? SingleChildScrollView(child: body) : body;
  }
}

// ─────────────────────────────────────────────
// Step 0 — Welcome
// ─────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return _OnboardingPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('👋  Welcome to\nWrite That Down', style: tt.headlineMedium),
          const SizedBox(height: 20),
          Text(
            'This is your voice-first thinking partner.',
            style: tt.titleMedium,
          ),
          const SizedBox(height: 20),
          _FeatureRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Chat with an AI',
            body: 'Type or talk to explore and refine your ideas in a conversational way.',
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: Icons.mic_none_rounded,
            title: 'Voice mode',
            body: 'Swipe right to speak freely. The app listens, the AI replies out loud.',
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: Icons.auto_awesome_rounded,
            title: '"Write that down"',
            body: 'Say the phrase mid-conversation and the app extracts and saves your idea automatically.',
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: Icons.grid_view_rounded,
            title: 'Idea tiles',
            body: 'Swipe left to see every saved idea as a structured tile you can riff on later.',
          ),
          const Spacer(),
          _PrimaryButton(label: 'Get started', onPressed: onNext),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Setup takes about 2 minutes.',
              style: tt.bodyMedium?.copyWith(color: const Color(0xFF7A6F5E)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step 1 — Pick a provider
// ─────────────────────────────────────────────

class _PickProviderPage extends StatelessWidget {
  const _PickProviderPage({
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  final ProviderType selected;
  final ValueChanged<ProviderType> onSelect;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return _OnboardingPage(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text('Choose your AI provider', style: tt.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'You\'ll need a free or paid account with one of these services. Your key is saved securely on-device and never leaves your phone.',
            style: tt.bodyLarge,
          ),
          const SizedBox(height: 20),
          for (final guide in _providerGuides.values)
            _ProviderOptionCard(
              guide: guide,
              isSelected: selected == guide.type,
              onTap: () => onSelect(guide.type),
            ),
          const SizedBox(height: 8),
          _PrimaryButton(label: 'Continue with ${_providerGuides[selected]!.type.displayName}', onPressed: onNext),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'You can add more providers later in Settings.',
              style: tt.bodyMedium?.copyWith(color: const Color(0xFF7A6F5E)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ProviderOptionCard extends StatelessWidget {
  const _ProviderOptionCard({
    required this.guide,
    required this.isSelected,
    required this.onTap,
  });

  final _ProviderGuide guide;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0EAD6) : const Color(0xFFFCF8F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF174C4F) : const Color(0xFFD4C9AE),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(guide.type.displayName, style: tt.titleMedium),
                      if (guide.type == ProviderType.groq ||
                          guide.type == ProviderType.google) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC9A227).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Free tier',
                            style: tt.bodySmall?.copyWith(
                              color: const Color(0xFF8B6F00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(guide.tagline, style: tt.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    guide.costNote,
                    style: tt.bodySmall?.copyWith(
                        color: const Color(0xFF7A6F5E)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF174C4F)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF174C4F)
                      : const Color(0xFFB0A48C),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step 2 — How to get the key
// ─────────────────────────────────────────────

class _InstructionsPage extends StatelessWidget {
  const _InstructionsPage({
    required this.guide,
    required this.onNext,
    required this.onBack,
  });

  final _ProviderGuide guide;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return _OnboardingPage(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text('Get your ${guide.type.displayName} API key',
              style: tt.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Follow these steps to create your key. The link you need is shown at the end of each step.',
            style: tt.bodyLarge,
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < guide.steps.length; i++)
            _StepRow(number: i + 1, text: guide.steps[i]),
          const SizedBox(height: 20),
          _UrlLinkBox(
            label: 'Open the key dashboard',
            url: guide.keyDashboardUrl,
          ),
          const SizedBox(height: 10),
          _UrlLinkBox(
            label: 'Or sign up for a new account',
            url: guide.signUpUrl,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8C84A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded,
                    color: Color(0xFF8B6F00), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your key is stored in the iOS Keychain. It never leaves your device.',
                    style: tt.bodyMedium?.copyWith(
                        color: const Color(0xFF5C4800)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _PrimaryButton(label: 'I have my key — continue', onPressed: onNext),
          const SizedBox(height: 10),
          _SecondaryButton(label: 'Back', onPressed: onBack),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF174C4F),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text,
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrlLinkBox extends StatelessWidget {
  const _UrlLinkBox({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => Clipboard.setData(ClipboardData(text: url)).then((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copied: $url')),
        );
      }),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF8F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD4C9AE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.open_in_new_rounded,
                    size: 16, color: Color(0xFF174C4F)),
                const SizedBox(width: 6),
                Text(label,
                    style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF174C4F))),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              url,
              style: tt.bodySmall?.copyWith(color: const Color(0xFF7A6F5E)),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to copy this URL',
              style: tt.bodySmall?.copyWith(
                  color: const Color(0xFFB0A48C),
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step 3 — Paste the key
// ─────────────────────────────────────────────

class _PasteKeyPage extends StatelessWidget {
  const _PasteKeyPage({
    required this.guide,
    required this.controller,
    required this.obscured,
    required this.onToggleObscure,
    required this.isSaving,
    required this.error,
    required this.onBack,
    required this.onFinish,
  });

  final _ProviderGuide guide;
  final TextEditingController controller;
  final bool obscured;
  final VoidCallback onToggleObscure;
  final bool isSaving;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return _OnboardingPage(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text('Paste your ${guide.type.displayName} key',
              style: tt.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Copy the key from the ${guide.type.displayName} dashboard and paste it below. It ${guide.keyHint.toLowerCase()}.',
            style: tt.bodyLarge,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFCF8F0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4C9AE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.vpn_key_rounded,
                        color: Color(0xFF174C4F), size: 20),
                    const SizedBox(width: 8),
                    Text(guide.type.displayName,
                        style: tt.titleMedium),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  obscureText: obscured,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: guide.keyHint,
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscured ? Icons.visibility : Icons.visibility_off),
                      onPressed: onToggleObscure,
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE57373)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(error!,
                              style: tt.bodyMedium
                                  ?.copyWith(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF9CB094)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    color: Color(0xFF3A6B3D), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saved to iOS Keychain. Never synced, never transmitted to anyone other than ${guide.type.displayName}.',
                    style:
                        tt.bodyMedium?.copyWith(color: const Color(0xFF2D532E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: isSaving ? 'Verifying API key…' : 'Start using Write That Down',
            onPressed: isSaving ? null : onFinish,
            loading: isSaving,
          ),
          const SizedBox(height: 10),
          _SecondaryButton(label: 'Back', onPressed: onBack),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared button components
// ─────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Feature row used on the welcome page
// ─────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF174C4F).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF174C4F), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: tt.titleMedium),
              const SizedBox(height: 2),
              Text(body, style: tt.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
