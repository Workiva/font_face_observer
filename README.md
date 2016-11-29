# Overview

Font load events, simple, small and efficient.
Dart port of https://github.com/bramstein/fontfaceobserver

# Usage Example

```dart
await new FontFaceObserver('Arial', weight: 'bold').load('/url/to/arial.ttf');
// at this point we're absolutely sure that the font has loaded
```

# Public API

```dart
// Constructing a new FontFaceObserver
FontFaceObserver(
    String this.family,
    {
        String this.style: 'normal',
        String this.weight: 'normal',
        String this.stretch: 'normal',
        String this.testString: 'BESbswy',
        int this.timeout: 3000,
        bool this.useSimulatedLoadEvents: false
    }
);

// Check if the font face is loaded successfully
Future<bool> isLoaded() async

// Load a font from the given URL by adding a font-face rule
// returns the same Future<bool> from isLoaded()
Future<bool> load(String url) async
```
