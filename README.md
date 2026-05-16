# BondedBrightness

Native macOS menu bar app that links two Studio Display brightness levels.

![Demo Video](bondedbrightness.mp4)

The main display is the source of truth. On each poll, the app reads the main
display brightness and writes the secondary display to the same level, adjusted
by the configured per-display offsets.

## Behavior

- Runs as a menu bar app.
- Uses the macOS main display as the primary source.
- Syncs the secondary Studio Display automatically.
- Supports pause/resume from the menu bar.
- Supports primary and secondary offsets in 5% steps.
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

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
