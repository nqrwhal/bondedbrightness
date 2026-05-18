# BondedBrightness

Native macOS menu bar app for syncing brightness across multiple Apple displays.


https://github.com/user-attachments/assets/0115908b-989f-4d01-abf3-8982f34fff86



BondedBrightness keeps a primary display and any number of linked displays in
sync. It can also choose the primary display from the display that currently
hosts the frontmost app's active window.

The app is model-agnostic and is intended for Apple displays that expose
software brightness control. It has been verified on Studio Display hardware,
and Apple documents brightness control for Pro Display XDR as well.

## Features

- Runs as a menu bar app.
- Supports manual primary selection and a focused-app heuristic.
- Syncs linked displays automatically.
- Supports pause/resume from the menu bar.
- Supports primary and linked offsets in 5% steps.
- Lets you identify displays from the menu bar.
- Persists pause, offset, and launch-at-login preferences with `UserDefaults`.
- Registers itself as a login item by default.

## Usage

Use the menu bar icon to:

- Choose the primary display source.
- Pause or resume syncing.
- Adjust primary and linked offsets.
- Identify connected displays.
- Toggle launch at login.

## Run

```bash
./script/build_and_run.sh
```

Verify the staged app launches:

```bash
./script/build_and_run.sh --verify
```

The Codex Run action is wired to the same script.

## Release

To create a disk image (`.dmg`) for distribution:

```bash
./script/create_dmg.sh
```

To build and upload a GitHub Release asset:

```bash
./script/release.sh v1.2.3
```

The repository also includes a GitHub Actions workflow that builds and uploads
the DMG automatically when you push a tag that starts with `v`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
