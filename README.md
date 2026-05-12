# Calculator Plasmoid (KDE Plasma 6)

A functional and lightweight calculator plasmoid for the KDE Plasma 6 desktop environment. This project is a refined fork of the original Debian-packaged calculator plasmoid, updated for modern Plasma standards and enhanced for specific hardware compatibility.

## Key Features & Improvements

- **Plasma 6 / Qt6 Compatibility:** Updated metadata format and QML event handling to ensure seamless performance on the latest KDE environments.
- **Hardware Optimization:** Dedicated logic to handle specific key events, ensuring a smooth experience with physical calculator keys on external keyboards.

## Development Context: The Dell KB740 "F9" Quirk

The primary catalyst for this fork was a hardware-specific behavior discovered with the Dell KB740 keyboard. On this model, the dedicated +/- key (intended for sign inversion) shares the same scancode as the F9 function key.

In many default calculator applications, this key goes unrecognized. This version specifically implements a fix that maps the F9/Sign-key event to the sign-toggle logic within the QML interface. This ensures that the Dell KB740's calculator keys perform their intended functions out of the box on KDE Plasma 6.

## Installation

Use kpackagetool6 to install the plasmoid to your local user directory:

```Bash
# Remove any existing version first
kpackagetool6 -t Plasma/Applet -r io.github.kawatab.calculator

# Install from the current directory
kpackagetool6 -t Plasma/Applet -i .
```

## Usage & Testing

To test the plasmoid functionality (including the F9 sign inversion) without adding it to your panel, run it in a standalone window:

```Bash
plasmawindowed io.github.kawatab.calculator
```

## License

This project is distributed under the same license as the original Debian package (GPL-2.0-or-later).