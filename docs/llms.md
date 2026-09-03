# Function Keys

> Function Keys is a small macOS menu bar app for viewing and changing the system's function-key mode.

The [project website](https://oneill9.github.io/function-keys/) describes the app. This file is a plain Markdown reference to its behaviour and installation.

## Install and use

Function Keys requires macOS 13 or later. Download the app from the [latest GitHub release](https://github.com/oneill9/function-keys/releases/latest). Public releases use Developer ID signing and Apple notarization.

Open the app and use its menu bar item. It does not open a normal app window or put an icon in the Dock. The menu offers two modes and marks the selected one with a checkmark.

- Standard function keys makes F1, F2 and the other function keys the primary actions. The menu bar icon reads "Fn".
- Hardware controls makes actions such as brightness and volume the primary actions. The menu bar icon shows "Fn" with a strikethrough.

The app changes the macOS global preference `com.apple.keyboard.fnState`. It checks for changes made outside the app, such as in System Settings, every 30 seconds.

## Scope and limitations

Function Keys switches the system setting. It does not assign custom actions to individual keys or provide per-app keyboard profiles. Keyboard hardware and macOS still determine which actions each key supports.

Bartender identifies its menu bar item as "Function Keys". The app keeps a stable item identity and accessibility label so menu bar tools can recognise it.

## Build from source

Clone the [source repository](https://github.com/oneill9/function-keys) and run these commands from its root.

```sh
swift run FunctionKeys
```

This launches the development executable. To create a local app bundle instead, run:

```sh
./scripts/build-app.sh
```

The bundle is `dist/Function Keys.app`. Local builds use ad-hoc signing and are not notarized. Use the published releases when you need the signed and notarized distribution.

## Project sources

- [README](https://raw.githubusercontent.com/oneill9/function-keys/main/README.md) documents current setup and behaviour.
- [Release process](https://oneill9.github.io/function-keys/release.md) describes packaging, signing and notarization.
- [Source repository](https://github.com/oneill9/function-keys) contains the implementation and issue tracker. The project uses the MIT license.
- [Short reference index](https://oneill9.github.io/function-keys/llms.txt) lists the main entry points.
