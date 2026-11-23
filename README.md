
       ▆▆                              ▆▆                     ▆▆
      ╱▆▆                             ╱╱╱                    ╱▆▆
     ▆▆▆▆▆▆  ▆▆▆▆▆  ▆▆▆▆▆▆ ▆▆▆▆▆▆▆▆▆▆  ▆▆ ▆▆▆▆▆▆▆   ▆▆▆▆▆▆   ╱▆▆        ▆▆▆▆▆▆   ▆▆▆▆▆▆  ▆▆▆▆▆▆
    ╱╱╱▆▆╱╱ ▆▆╱╱╱▆▆╱╱▆▆╱╱▆╱╱▆▆╱╱▆▆╱╱▆▆╱▆▆╱╱▆▆╱╱╱▆▆ ╱╱╱╱╱╱▆▆  ╱▆▆       ╱╱╱╱╱╱▆▆ ╱▆▆╱╱╱▆▆╱▆▆╱╱╱▆▆
      ╱▆▆  ╱▆▆▆▆▆▆▆ ╱▆▆ ╱╱ ╱▆▆ ╱▆▆ ╱▆▆╱▆▆ ╱▆▆  ╱▆▆  ▆▆▆▆▆▆▆  ╱▆▆        ▆▆▆▆▆▆▆ ╱▆▆  ╱▆▆╱▆▆  ╱▆▆
      ╱▆▆  ╱▆▆╱╱╱╱╱ ╱▆▆    ╱▆▆ ╱▆▆ ╱▆▆╱▆▆ ╱▆▆  ╱▆▆ ▆▆╱╱╱╱▆▆  ╱▆▆       ▆▆╱╱╱╱▆▆ ╱▆▆▆▆▆▆╱╱▆▆▆▆▆▆╱
      ╱╱▆▆ ╱╱▆▆▆▆▆▆╱▆▆▆    ▆▆▆ ╱▆▆ ╱▆▆╱▆▆ ▆▆▆  ╱▆▆╱╱▆▆▆▆▆▆▆▆ ▆▆▆      ╱╱▆▆▆▆▆▆▆▆╱▆▆╱╱╱╱ ╱▆▆╱╱╱╱
       ╱╱╱  ╱╱╱╱╱╱╱╱╱╱╱   ╱╱╱╱ ╱╱╱ ╱╱╱╱╱╱╱╱╱╱  ╱╱╱ ╱╱╱╱╱╱╱╱╱╱╱╱╱ ▆▆▆▆▆ ╱╱╱╱╱╱╱╱╱╱▆▆     ╱▆▆
                                                                ╱╱╱╱╱╱          ╱╱╱     ╱╱╱

    a small library for building interactive terminal applications.


## usage

implement `TerminalApp` by adding event handlers to your app class:
- `acceptHostAPIs()` - get a reference to the app host and screen api
- `onUpdate()` - update the screen based on state
- `onKeyRecord()` - update state based on user keyboard input
- `onResize()` - adjust to new screen size

then instantiate an instance of `TerminalAppRunner`, passing in your app to be run:

```dart
void main(List<String> args) {
  TerminalAppRunner(
    fps: 2,
    title: 'App Title',
  ).run(MyApp(args));
}
```


## examples

minimal app hooked up to frame and key events:

```console
dart run example/example.dart
```


## features

event handlers
- time-based frame updates
- keyboard presses
- screen resize

terminal management
- setup and restoration of stdin and stdout state
- alternate buffer use
- reading and writing virtual terminal sequences
  - queries and supports kitty keyboard protocol where available
  - default support on windows is comparable (down / up + modifiers)
  - falls back to press-only on posix


## installation

add `terminal_app` to `pubspec.yaml`:

```console
dart pub add terminal_app
```

or manually:

```yaml
dependencies:
  terminal_app: ^1.0.0
```

fetch dependencies:

```console
dart pub get
```

import package:

```dart
import 'package:terminal_app/terminal_app.dart';
```
