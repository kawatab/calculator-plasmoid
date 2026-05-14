# Calculator Plasmoid (KDE Plasma 6)

A functional and lightweight calculator plasmoid for the KDE Plasma 6 desktop environment. This project is a refined fork of the original Debian-packaged calculator plasmoid, updated for modern Plasma standards and enhanced for specific hardware compatibility.

## Key Features & Improvements

- **Plasma 6 / Qt6 Compatibility:** Updated metadata format and QML event handling to ensure seamless performance on the latest KDE environments.
- **Hardware Optimization:** Dedicated logic to handle specific key events, ensuring a smooth experience with physical calculator keys on external keyboards.

## Development Context: Supporting the F9 Scancode Convention

The motivation for this fork came after I switched to a new keyboard featuring a dedicated +/- key. I discovered that these keys commonly use the F9 scancode—a detail I had never noticed with my previous keyboard. Since this key is often unrecognized by default, I implemented a fix that maps the F9 event to the sign-toggle logic in the QML interface, ensuring "out-of-the-box" compatibility for most hardware calculator keys on KDE Plasma 6.

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