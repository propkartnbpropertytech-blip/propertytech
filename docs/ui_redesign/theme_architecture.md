# Theme Architecture

```
ThemeManager (ChangeNotifier + SharedPreferences)
        │
        ▼
MaterialApp.router
  theme: PropKartTheme.light()
  darkTheme: PropKartTheme.dark()
        │
        ├── ColorScheme (Material 3)
        ├── TextTheme (Inter / SF)
        ├── Component themes (AppBar, Card, Dialog, Input, SnackBar…)
        └── extensions: [PropKartColors]

CRMColors.*  ──static──► ThemeManager.isDarkMode
CRMColors.*Of(context) ──► PropKartColors ThemeExtension (fallback to static)
AppColors / AppSpacing ──► facades over CRM*
```

## Light

Bright grouped backgrounds (`#F7F6F2`), white elevated surfaces, brand green `#688A75`, soft shadows, minimal 0.5px borders.

## Dark

Layered OLED-friendly surfaces (`#0A0E16` → `#141A26` → `#1A2232`), glass translucency, soft highlights, brand green `#5CA380`.
