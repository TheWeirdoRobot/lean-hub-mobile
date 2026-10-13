# LEAN Hub — iOS app

Flutter companion app for the LEAN Hub website. It talks to the **same Supabase
project** as the website and never changes the schema or RLS policies.

Done so far: Sign-in, My Tasks (realtime), Task Detail with photo thumbnails,
Capture (camera/library → caption → upload) and Settings. Timeline and
Components are placeholders for now.

## Settings

Stored on the device with `shared_preferences` (not synced to Supabase):

| Setting | Effect |
| --- | --- |
| Wi-Fi-only uploads | Capture asks before uploading over cellular data |
| Photo quality | High 2048 px / Standard 1600 px / Data saver 1024 px (JPEG) |
| Default sub-team filter | Pre-selected in My Tasks |
| Theme | Dark (default), Light, or match the iPhone |

## Requirements

- Flutter 3.47+ (`flutter --version`)
- Xcode 26+ with an iOS Simulator runtime
- A LEAN Hub account (accounts are created on the website; the app has no sign-up)

## 1. Configure Supabase

The URL and anon key are passed at build time with `--dart-define-from-file`.
They are never hardcoded, and `env.json` is gitignored.

```sh
cp env.example.json env.json
```

Fill in `env.json` with the same values as the website's `VITE_SUPABASE_URL`
and `VITE_SUPABASE_ANON_KEY` (Supabase dashboard → Project Settings → API):

```json
{
  "SUPABASE_URL": "https://abcd1234.supabase.co",
  "SUPABASE_ANON_KEY": "eyJ..."
}
```

> Use the **anon / publishable** key only. Never put the `service_role` key in
> this app; anything compiled into an app can be extracted.

If you run without this file, the app shows a "Supabase is not configured"
screen instead of crashing.

## 2. Run on the iOS Simulator

```sh
flutter pub get
open -a Simulator
flutter run --dart-define-from-file=env.json
```

In VS Code, the **LEAN Hub (debug)** launch configuration in
`.vscode/launch.json` already passes the flag. Press F5.

## 3. Run on a physical iPhone (free Apple ID)

1. Plug in the iPhone and tap **Trust This Computer**. On iOS 16+, also turn on
   **Settings → Privacy & Security → Developer Mode** and restart the phone.
2. Open `ios/Runner.xcworkspace` in Xcode.
3. Select the **Runner** target → **Signing & Capabilities**:
   - Tick **Automatically manage signing**.
   - **Team**: choose *Add an Account…*, sign in with your Apple ID, then pick
     "Your Name (Personal Team)".
   - **Bundle Identifier**: `edu.boisestate.leanhub`. If Xcode reports that it's
     already taken, change it to something unique, e.g.
     `edu.boisestate.leanhub.yourname`.
4. From the project folder:
   ```sh
   flutter devices                       # find your iPhone's id
   flutter run -d <iphone-id> --dart-define-from-file=env.json
   ```
5. The first launch is blocked until you trust the developer. On the phone, go to
   **Settings → General → VPN & Device Management → (your Apple ID) → Trust**,
   then run again.

Free-account builds expire after **7 days**. Run `flutter run` again to
reinstall.

### Testing Capture on the Simulator

The Simulator has no camera, so **Take photo** shows a message — use
**Choose from library**. To put your own pictures in the Simulator's library,
drag image files onto the Simulator window.

## Tests and analysis

```sh
flutter analyze
flutter test
```

## Project layout

```
lib/
  main.dart            Supabase init from --dart-define values
  app.dart             MaterialApp.router, theme, repository scope
  router.dart          go_router: auth redirect + bottom-nav shell
  core/                env, theme, dates, shared loading/empty/error widgets
  models/              plain Dart models with fromJson
    taxonomy.dart      sub-teams, statuses, phases, priorities (like teams.js)
  data/                one repository per table — the only code that calls Supabase
  features/<page>/     screens
test/                  model, slug-mapping, filter, redirect and widget tests
```

**State management:** plain `StatefulWidget` + `setState`, with repositories
provided by an `InheritedWidget`. The screens are small and own their own
data, so a state library would add concepts without removing any code.

## Conventions shared with the website

- `tasks.status` stores a slug (`"In Progress"` → `in_progress`, see
  `statusToValue`). Names, colors and order come from `custom_statuses`; if that
  table is empty, the app falls back to the website's defaults. Unlike the
  website, the app only reads it and never seeds it.
- `tasks.assignee_ids` is the source of truth for assignees, and `assigned_to`
  mirrors the first one. Anything that edits assignees must write both. The app
  doesn't edit assignees yet.
- Attachments: private `task-files` bucket, object path
  `{userId}/{taskId}/{timestamp}-{safeName}`, then a `files` row
  (`FileRepository.uploadToTask`). Read them with signed URLs
  (`FileRepository.signedUrls`).
- Photos are resized and re-encoded as JPEG per the Photo quality setting,
  which also turns iPhone HEIC photos into something browsers can show.
- Captions: `files` has no caption column, so a caption is posted as a task
  comment: `Photo IMG_20261013_101500.jpg: <caption>`.
- "My tasks" uses the website's rule (`taskPeople.js`): tasks naming you, plus
  unassigned tasks for the Full Team or your profile's sub-team.
