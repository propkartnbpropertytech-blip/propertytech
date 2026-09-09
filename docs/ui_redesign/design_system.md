# PropKart Design System

Apple-inspired premium UI tokens for PropKart CRM. Original design inspired by HIG principles — not a copy of Apple assets.

## Typography

- **Apple platforms (iOS/macOS):** system font (SF Pro)
- **Elsewhere:** Inter via `google_fonts`

Scale: `largeDisplay`, `largeTitle`, `display`, `title`, `pageTitle`, `navigationTitle`, `headline`, `sectionTitle`, `sectionHeader`, `cardTitle`, `body`, `bodyMedium`, `subheadline`, `label`, `footnote`, `caption`, `captionBold`, `button`, `statistics`, `chartLabel`, `tableHeader`

## Colors

Use `CRMColors` static getters (ThemeManager-aware) or `PropKartColors.of(context)` ThemeExtension.

Roles: background, groupedBackground, surface/cardBg, surfaceElevated, sidebarBg, glassSurface, primary, primaryHover, secondary, accent, border, divider, text, textSecondary, textMuted, success, warning, danger, info, disabled, overlay, shadow, chartColors, graphColors, gradientPrimary, skeletonBase/Highlight

## Spacing

`CRMSpacing`: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64

## Radius

`CRMBorderRadius`: 4, 8, 12, 16, 20 (`ml`), 24 (`xl`), 28 (`xxl`), 32 (`huge`), 40 (`mega`), round

## Shadows

`CRMShadows`: small/soft, medium, large, floating, glass, modal, primaryGlow

## Blur

`CRMBlur`: navigation 20, dialog 24, bottomSheet 28, search 24, floatingPanel 30, reduced 8

## Motion

`CRMMotion`: fast 150ms, medium 280ms, slow 420ms, springs, ease curves, page/tab/dialog/sheet durations

## Theme

```dart
theme: PropKartTheme.light(),
darkTheme: PropKartTheme.dark(),
```

Theme preference persists via `ThemeManager` + `shared_preferences`.

## Glass

`CRMGlassSurface` — BackdropFilter + translucent fill. Prefer for nav/search overlays; avoid continuous blur on long scrolling lists.

## Legacy facades

`AppColors` / `AppSpacing` / `AppTextStyles` / `PremiumButton` / `PremiumTextField` remain for auth compatibility and delegate to CRM tokens.
