import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/utils/seo_helper.dart';

/// Landing page for PropKart, implementing Shubhangi's luxury design:
/// - Full-bleed villa background image (`landing_villa.jpg` / `landing_villa.webp`)
/// - Multi-stop dark scrim overlay (`rgba(5, 10, 8, ...)`)
/// - Navigation bar with NB monogram logo mark and bold "PropKart" branding
/// - Editorial hero headline in Inclusive Sans with dropped shadow
/// - Hero description in Inter with ambient shadow
/// - Crisp white "Log In" card button with designer vector arrow
class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  static const _charcoalDark = Color(0xFF050A08);

  @override
  void initState() {
    super.initState();
    SeoHelper.updateTags(
      title: 'PropKart - Discover Properties That Feel Like Home',
      description:
          'Explore premium properties, discover your perfect match, and make your next move with confidence with PropKart.',
      canonicalUrl: 'https://propkart.nbpropertytech.com/get-started',
      imageUrl: 'https://propkart.nbpropertytech.com/assets/images/landing_villa.jpg',
    );
  }

  bool _imagePrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagePrecached) {
      _imagePrecached = true;
      // Lazily precache assets after the initial frame has rendered so the UI is immediately responsive
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        precacheImage(const AssetImage('assets/images/landing_villa.webp'), context).catchError((_) {});
        precacheImage(const AssetImage('assets/images/landing_logo.webp'), context).catchError((_) {});
      });
    }
  }

  void _goToLogin() {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from != null && from.isNotEmpty) {
      context.go('/login?from=${Uri.encodeComponent(from)}');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _charcoalDark,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final isDesktop = width >= 900;
          final isTablet = width >= 600 && width < 900;

          // Responsive sizing matching designer CSS clamp rules
          final double hPadding = isDesktop
              ? (width * 0.04).clamp(32.0, 64.0)
              : (isTablet ? 32.0 : 24.0);
          final double topPadding = isDesktop ? 40.0 : 24.0;
          final double bottomPadding = isDesktop
              ? (height * 0.08).clamp(40.0, 96.0)
              : 32.0;

          final double logoSize = isDesktop ? 50.0 : (isTablet ? 44.0 : 40.0);
          final double brandFontSize = isDesktop ? 36.0 : (isTablet ? 30.0 : 26.0);

          // Hero title clamp(48px, 5.9vw, 85px)
          final double titleFontSize = isDesktop
              ? (width * 0.052).clamp(48.0, 78.0)
              : (isTablet ? 42.0 : 32.0);

          // Description clamp(18px, 2.1vw, 30px)
          final double descFontSize = isDesktop
              ? (width * 0.018).clamp(18.0, 26.0)
              : (isTablet ? 17.0 : 15.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Photographic Villa Background (fast-fetching WebP with progressive fallback & smooth frameBuilder)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/landing_villa.webp',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  alignment: isDesktop
                      ? Alignment.center
                      : const Alignment(0.15, 0.0),
                  filterQuality: FilterQuality.medium,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded || frame != null) {
                      return AnimatedOpacity(
                        opacity: frame != null ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        child: child,
                      );
                    }
                    return const ColoredBox(color: _charcoalDark);
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/landing_villa.jpg',
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      alignment: isDesktop
                          ? Alignment.center
                          : const Alignment(0.15, 0.0),
                      filterQuality: FilterQuality.medium,
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) {
                          return AnimatedOpacity(
                            opacity: frame != null ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            child: child,
                          );
                        }
                        return const ColoredBox(color: _charcoalDark);
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(color: _charcoalDark);
                      },
                    );
                  },
                ),
              ),

              // 2. Designer Multi-Stop Scrim Gradient (title-scrim)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: isDesktop
                          ? const [0.0, 0.3538, 0.5498, 0.6818, 0.9971]
                          : const [0.0, 0.28, 0.52, 0.72, 1.0],
                      colors: isDesktop
                          ? [
                              _charcoalDark.withValues(alpha: 0.12),
                              _charcoalDark.withValues(alpha: 0.12),
                              _charcoalDark.withValues(alpha: 0.12),
                              _charcoalDark.withValues(alpha: 0.18),
                              _charcoalDark.withValues(alpha: 0.60),
                            ]
                          : [
                              _charcoalDark.withValues(alpha: 0.08),
                              _charcoalDark.withValues(alpha: 0.16),
                              _charcoalDark.withValues(alpha: 0.32),
                              _charcoalDark.withValues(alpha: 0.58),
                              _charcoalDark.withValues(alpha: 0.85),
                            ],
                    ),
                  ),
                ),
              ),

              // 3. Foreground Content with Responsive Viewport Safety
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPadding,
                    vertical: topPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Navigation Bar
                      _LandingNavigationBar(
                        logoSize: logoSize,
                        brandFontSize: brandFontSize,
                      ),

                      // Spacer / Hero container positioned towards bottom-left
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: bottomPadding * 0.5),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isDesktop ? 752.0 : double.infinity,
                              ),
                              child: SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                child: _HeroContent(
                                  isDesktop: isDesktop,
                                  titleFontSize: titleFontSize,
                                  descFontSize: descFontSize,
                                  onLogIn: _goToLogin,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Top Navigation brand lockup: 50x50 logo + "PropKart" in Inter Bold
class _LandingNavigationBar extends StatelessWidget {
  final double logoSize;
  final double brandFontSize;

  const _LandingNavigationBar({
    required this.logoSize,
    required this.brandFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand Mark Logo (vector-icon)
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.15),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/landing_logo.webp',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/images/landing_logo.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Colors.black,
                  child: Icon(Icons.apartment_rounded, color: Color(0xFFD9AD6E)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Brand Name (brand2)
        Text(
          'PropKart',
          style: GoogleFonts.inter(
            fontSize: brandFontSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF050A08),
            letterSpacing: -0.5,
            height: 1.0,
            shadows: const [
              Shadow(
                color: Color.fromRGBO(255, 255, 255, 0.45),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hero section: Headline, description, and white Log In button
class _HeroContent extends StatelessWidget {
  final bool isDesktop;
  final double titleFontSize;
  final double descFontSize;
  final VoidCallback onLogIn;

  const _HeroContent({
    required this.isDesktop,
    required this.titleFontSize,
    required this.descFontSize,
    required this.onLogIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hero Title (Inclusive Sans Bold with 95% line-height & shadow)
        Text(
          'Discover Properties That Feel Like Home.',
          style: GoogleFonts.inclusiveSans(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 0.96,
            letterSpacing: -0.6,
            shadows: const [
              Shadow(
                color: Color.fromRGBO(0, 0, 0, 0.66),
                offset: Offset(1, 8),
                blurRadius: 0,
              ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 24.0 : 16.0),

        // Description (Inter Regular with 120% line-height & shadow)
        Text(
          'Explore premium properties, discover your perfect match, and make your next move with confidence.',
          style: GoogleFonts.inter(
            fontSize: descFontSize,
            fontWeight: FontWeight.w400,
            color: const Color.fromRGBO(255, 255, 255, 0.80),
            height: 1.25,
            letterSpacing: -0.2,
            shadows: const [
              Shadow(
                color: Color.fromRGBO(0, 0, 0, 0.85),
                offset: Offset(0, 5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 28.0 : 22.0),

        // Log In Button (White card with dark typography & vector arrow)
        _DesignerLogInButton(
          isDesktop: isDesktop,
          onPressed: onLogIn,
        ),
      ],
    );
  }
}

/// Interactive Log In button matching Shubhangi's Figma specifications:
/// 183px width, 12px border radius, white bg, dark text, custom vector arrow
class _DesignerLogInButton extends StatefulWidget {
  final bool isDesktop;
  final VoidCallback onPressed;

  const _DesignerLogInButton({
    required this.isDesktop,
    required this.onPressed,
  });

  @override
  State<_DesignerLogInButton> createState() => _DesignerLogInButtonState();
}

class _DesignerLogInButtonState extends State<_DesignerLogInButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = widget.isDesktop ? 183.0 : 164.0;
    final double buttonHeight = widget.isDesktop ? 54.0 : 48.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          scale: _isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: buttonWidth,
            height: buttonHeight,
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0xFFF8F9FA) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? const Color.fromRGBO(0, 0, 0, 0.32)
                      : const Color.fromRGBO(0, 0, 0, 0.20),
                  offset: Offset(0, _isHovered ? 6 : 4),
                  blurRadius: _isHovered ? 16 : 12,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Log In',
                  style: GoogleFonts.inter(
                    fontSize: widget.isDesktop ? 18.0 : 16.0,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF050A08),
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 10),
                const _DesignerArrowVector(
                  color: Color(0xFF050A08),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Exact vector recreation of designer's `Arraow.svg`:
/// ```xml
/// <svg width="16" height="15" viewBox="0 0 16 15" fill="none">
/// <path d="M1 7.5H15M8.875 14L15 7.5L8.875 1" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
/// </svg>
/// ```
class _DesignerArrowVector extends StatelessWidget {
  final Color color;
  final double size;

  const _DesignerArrowVector({
    this.color = const Color(0xFF050A08),
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * (15.0 / 16.0),
      child: CustomPaint(
        painter: _ArrowPainter(color: color),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;

  const _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final scaleX = size.width / 16.0;
    final scaleY = size.height / 15.0;

    final path = Path();
    // Horizontal stem: M1 7.5 H15
    path.moveTo(1.0 * scaleX, 7.5 * scaleY);
    path.lineTo(15.0 * scaleX, 7.5 * scaleY);

    // Chevron: M8.875 14 L15 7.5 L8.875 1
    path.moveTo(8.875 * scaleX, 14.0 * scaleY);
    path.lineTo(15.0 * scaleX, 7.5 * scaleY);
    path.lineTo(8.875 * scaleX, 1.0 * scaleY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
