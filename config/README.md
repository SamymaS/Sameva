# Configuration de l'app (dart-define)

Copier `exemple.json` en `dev.json` (ou `staging.json`, `prod.json`), renseigner
les valeurs, puis lancer :

```bash
flutter run --dart-define-from-file=config/dev.json
flutter build apk --release --dart-define-from-file=config/prod.json
```

Ces fichiers sont ignorés par Git (sauf l'exemple). Ils ne contiennent que des
valeurs **publiques par conception** : URL Supabase, clé anon (protégée par la
RLS), ID client Web Google. Les secrets (clé service_role, Anthropic, Stripe)
vivent uniquement côté serveur, dans les secrets Supabase.

Sous Android Studio / VS Code : ajouter `--dart-define-from-file=config/dev.json`
aux arguments de lancement.
