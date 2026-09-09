# Accessibility & Performance Notes

## Accessibility

- Semantic colors keep success/warning/danger/info distinct in light and dark
- Primary buttons use white on brand green (contrast-checked against `#688A75`)
- Touch targets: CRMButton default height 48 (≥44)
- Text styles respect MediaQuery text scaling (no hardcoded layout that clamps scale)
- Dialogs use `barrierLabel` for screen readers
- Charts: center labels use high-contrast text tokens; segment colors from chart palette

## Performance

- Glass/blur wrapped in `RepaintBoundary` (shell top bar, CRMGlassSurface)
- Blur sigma reduced when `MediaQuery.disableAnimations` is true
- Avoid BackdropFilter on list item cells — only chrome (nav/dialogs/sheets)
- Chart animation is one-shot TweenAnimationBuilder (no continuous ticker after settle)
- Skeleton shimmer uses single AnimationController per instance

## Validation checklist

- [ ] No business logic / API changes (manual review)
- [ ] Light mode smoke: login → dashboard → properties → requirements
- [ ] Dark mode smoke: same path + settings toggle persistence across restart
- [ ] Mobile width (<768): bottom nav + quick actions sheet
- [ ] Desktop (≥768): sidebar collapse + search overlay
- [ ] Charts render light/dark
- [ ] Dialogs/sheets open with motion; no overflow
- [ ] Share public pages readable CTAs

## Maintenance

1. Add new colors only to `PropKartColors` + `CRMColors` together
2. Prefer `CRMColors.*Of(context)` in new widgets
3. Never introduce random spacing — use `CRMSpacing`
4. Prefer CRM* widgets over one-off Material chrome
5. Keep `App*` facades until auth fully migrated, then remove
