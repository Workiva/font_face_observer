# Overview

Font load events, simple, small and efficient.
Dart port of https://github.com/bramstein/fontfaceobserver

# Usage Example

```dart
await new FontFaceObserver('Arial', weight: 'bold').load('/url/to/arial.ttf');
// at this point we're absolutely sure that the font has loaded
```

# Run the demo

To run the demo, just install dependencies and run pub serve. 
Then open http://localhost:8080 
```
pub get
pub serve
``

# Public API

```dart
// Constructing a new FontFaceObserver (with default values)
FontFaceObserver(
    String family,
    {
        String style: 'normal',
        String weight: 'normal',
        String stretch: 'normal',
        String testString: 'BESbswy',
        int timeout: 3000,
        bool useSimulatedLoadEvents: false
    }
);

// Check if the font face is loaded successfully
Future<bool> isLoaded() async

// Load a font from the given URL by adding a font-face rule
// returns the same Future<bool> from isLoaded()
Future<bool> load(String url) async
```

# Notes
Font Face Observer will use the FontFace API
https://developer.mozilla.org/en-US/docs/Web/API/FontFace if available to detect
when a font has loaded. If the browser does not support that API it will
fallback to the method used in https://github.com/bramstein/fontfaceobserver which
relies on scroll events when the font loads and is quite efficient. If you want
to force the use of the fallback mode, you can set
`useSimulatedLoadEvents: true` when constructing your FontFaceObserver.
