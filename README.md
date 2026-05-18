# BondedBrightness

Native macOS menu bar app that links two Studio Display brightness levels.


https://github.com/user-attachments/assets/0115908b-989f-4d01-abf3-8982f34fff86



The app can use the main display, another display, or the display that
currently hosts the frontmost app's active window as the primary display. On
each poll, it reads the primary display brightness and writes every linked
display to the same level, adjusted by the configured per-display offsets.

## Behavior

- Runs as a menu bar app.
- Supports manual primary selection and a focused-app heuristic.
- Syncs linked Studio Displays automatically.
- Supports pause/resume from the menu bar.
- Supports primary and linked offsets in 5% steps.
- Lets you identify displays from the menu bar.
- Persists pause, offset, and launch-at-login preferences with `UserDefaults`.
- Registers itself as a login item by default.

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
