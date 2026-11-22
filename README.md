a minimal library for building interactive terminal applications.

## features

event handlers
- time-based frame updates
- keyboard presses
- screen resize

terminal management
- setup and restoration of stdin and stdout state
- alternate buffer use
- reading and writing virtual terminal sequences


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


## usage

add event handler methods to your app class to implement `TerminalApp`:
- `acceptHostAPIs()`
- `onUpdate()`
- `onKeyRecord()`
- `onResize()`

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
