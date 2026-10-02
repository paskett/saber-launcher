# Plan: Saber → E-Ink Launcher

Goal: turn this Saber fork into an Android home-screen launcher for a black-and-white
e-ink tablet. Your notebook *is* your home screen. Apps are launched via a
Spotlight/OLauncher-style type-to-launch overlay opened from the editor toolbar.

Keep everything simple. No new pub dependencies — use a MethodChannel for the
native side (plugins like `device_apps` are discontinued).

## Phase 1 — Declare the app as a HOME launcher

File: `android/app/src/main/AndroidManifest.xml`

- Add to `MainActivity`'s MAIN intent-filter:
  - `<category android:name="android.intent.category.HOME" />`
  - `<category android:name="android.intent.category.DEFAULT" />`
  (keep the existing `LAUNCHER` category so the app still shows in other launchers' drawers)
- Change `MainActivity`'s `android:launchMode` from `singleTop` to `singleTask`
  (recommended for home activities).
- No permission needed to be a launcher. To *list* other apps on Android 11+,
  add a `<queries>` entry (top level of manifest, next to the existing one):
  ```xml
  <intent>
      <action android:name="android.intent.action.MAIN" />
      <category android:name="android.intent.category.LAUNCHER" />
  </intent>
  ```

Done when: manifest contains HOME/DEFAULT categories, singleTask, and the queries entry.

## Phase 2 — Native app list + launch (MethodChannel)

File: `android/app/src/main/kotlin/com/adilhanney/saber/MainActivity.kt`

- Channel name: `com.adilhanney.saber/launcher`
- Register in `configureFlutterEngine(flutterEngine: FlutterEngine)` (call super first).
- Methods:
  - `listApps` → returns `List<Map<String, String>>` with keys `label` and
    `packageName`. Implementation: `packageManager.queryIntentActivities(
    Intent(ACTION_MAIN).addCategory(CATEGORY_LAUNCHER), 0)`, map to
    `label = loadLabel(pm)`, `packageName = activityInfo.packageName`.
    Exclude this app's own package (`com.adilhanney.saber`). Sort by label,
    case-insensitive. Dedupe by packageName.
  - `launchApp` (arg: `packageName` String) → 
    `packageManager.getLaunchIntentForPackage(packageName)`, add
    `FLAG_ACTIVITY_NEW_TASK`, `startActivity`. Return true/false; call
    `result.error` on exceptions.
- No icons needed (e-ink, text-only UI).

Done when: MainActivity.kt compiles and handles both methods.

## Phase 3 — Flutter: Spotlight-style app launcher UI

New files:
- `lib/data/app_launcher.dart` — thin wrapper over the MethodChannel
  `com.adilhanney.saber/launcher`:
  - `class AppInfo { final String label; final String packageName; }`
  - `Future<List<AppInfo>> listApps()`
  - `Future<void> launchApp(String packageName)`
  - Guard everything with `Platform.isAndroid`.
- `lib/components/app_launcher/app_launcher_dialog.dart` — Spotlight-like
  overlay, shown via `showDialog` (or a top-aligned `Dialog`):
  - A single autofocused `TextField` (search bar look: rounded rectangle,
    prominent, high-contrast — remember black & white e-ink, avoid grays
    and animations).
  - Below it, the filtered list of app labels (case-insensitive substring
    match on label; prefix matches sorted first).
  - **OLauncher behavior: when filtering leaves exactly one app, launch it
    immediately** and pop the dialog.
  - Enter/submit launches the first result. Tapping a result launches it.
    Esc / tapping outside dismisses.
  - Load the app list once on open (show nothing/spinner until loaded).
  - Expose a helper: `Future<void> showAppLauncherDialog(BuildContext context)`.

Done when: dialog works standalone and launches apps.

## Phase 4 — Toolbar button in the writing menu

File: `lib/components/toolbar/toolbar.dart`

- Add a `ToolbarIconButton` alongside the existing buttons (e.g. near the
  export/fullscreen buttons at the end):
  - tooltip: plain string `'Launch app'` (don't touch the i18n pipeline),
  - icon: `Icons.rocket_launch` (or `Icons.apps`),
  - onPressed: `showAppLauncherDialog(context)`,
  - only include the button when `Platform.isAndroid`.
- Follow the existing `ToolbarIconButton` usage pattern (padding:
  buttonPadding, etc.).

Done when: button appears in the editor toolbar and opens the launcher dialog.

## Verification

- `flutter analyze` should pass for touched Dart files (pre-existing issues OK).
- Build check if tooling is available: `flutter build apk --debug`.
- Manual: install on tablet, press home → chooser should offer Saber;
  toolbar button → type app name → launches when one match remains.

## Future ideas (not now)

- Pinned-app dock, `@appname` inline links in notes, "today's page" on home
  press, settings shortcut safeguard, recent/frequent app ranking.
