# Copy env/local.env.example to env/local.env first.
# Backend container must already be running on http://127.0.0.1:5001 with APP_ENV=local.

Set-Location $PSScriptRoot\..
flutter run --dart-define-from-file=env/local.env
