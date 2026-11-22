import 'dart:io';
import 'dart:math' as math;

import 'package:grinder/grinder.dart';
import 'package:path/path.dart' as path_util;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:pub_semver/pub_semver.dart';

final Directory _docDir = Directory('doc/api');
bool _hasExe = false;

Never _missingPubspecArgs() => throw ArgumentError.value(
  null,
  'pubspecFile',
  'pubspec and pubspecFile cannot both be null; one must be provided.',
);

Never _fail(String message) {
  log('');
  log(message);
  log('exiting.');
  // exit without a stack trace
  exit(1);
}

Never _failOnMissingPubspecField(String fieldName, {File? file}) {
  final String path = file?.path ?? '';
  final String info = path.isEmpty ? '' : ' at ${path}';
  _fail('pubspec${info} has no ${fieldName} field');
}

void _showTokenInSource(String token, GrinderContext context) {
  final String wd = libDir.parent.path;
  try {
    if (Platform.isWindows) {
      run(
        'findstr',
        arguments: <String>['/n', '/s', token, '*.dart'],
        runOptions: RunOptions(workingDirectory: wd),
      );
    } else {
      run(
        'grep',
        arguments: <String>[token, '--line-number', '--recursive', '--include', r'\*.dart'],
      );
    }
  } on ProcessException catch (e) {
    final TaskArgs args = context.invocation.arguments;
    final bool isVerbose = args.getFlag('verbose');
    if (isVerbose) {
      log('error');
      log('  workingDirectory: ${wd}');
      log('  exitCode: ${e.exitCode}');
      log('  stdout: ${e.stderr}');
    } else {
      log("no results for '$token'");
    }
  }
}

File _getPubspecFile(String pubspecPath) {
  return File(path_util.join(pubspecPath, 'pubspec.yaml'));
}

File _getVersionFile(String srcPath) {
  return File(path_util.join(srcPath, 'version.dart'));
}

Pubspec _getPubSpec(File pubspecFile) {
  return Pubspec.parse(pubspecFile.readAsStringSync());
}

Pubspec _pubspec({Pubspec? spec, File? file}) {
  if (spec == null && file == null) {
    _missingPubspecArgs();
  }
  return spec ?? _getPubSpec(file!);
}

String _getNameFromPubspec({Pubspec? pubspec, File? pubspecFile}) {
  return _pubspec(spec: pubspec, file: pubspecFile).name;
}

Map<String, String?> _getExecutablesFromPubspec({Pubspec? pubspec, File? pubspecFile}) {
  return _pubspec(spec: pubspec, file: pubspecFile).executables;
}

Version _getVersionFromPubspec({Pubspec? pubspec, File? pubspecFile}) {
  return _pubspec(spec: pubspec, file: pubspecFile).version ??
      _failOnMissingPubspecField('version', file: pubspecFile);
}

void _writeVersionToPubspec(Version newVersion, File pubspecFile) {
  final Version oldVersion = _getVersionFromPubspec(pubspecFile: pubspecFile);

  // replace only version line to preserve comments and formatting in rest of file
  final String yaml = pubspecFile.readAsStringSync().replaceFirst(
    'version: ${oldVersion}',
    'version: ${newVersion}',
  );
  pubspecFile.writeAsStringSync(yaml, flush: true);
}

void _writeVersionToSource(Version newVersion, File versionFile) {
  versionFile.writeAsStringSync("const String packageVersion = '${newVersion}';\n", flush: true);
}

void _syncVersionWithPubspec(File versionFile, File pubspecFile) {
  _writeVersionToSource(_getVersionFromPubspec(pubspecFile: pubspecFile), versionFile);
}

void _updateVersion(
  File pubspecFile,
  File versionFile, {
  int majorInc = 0,
  int minorInc = 0,
  int patchInc = 0,
  bool resetMajor = false,
  bool resetMinor = false,
  bool resetPatch = false,
}) {
  final Version v1 = _getVersionFromPubspec(pubspecFile: pubspecFile);
  final int x = resetMajor ? 0 : v1.major + majorInc;
  final int y = resetMinor ? 0 : v1.minor + minorInc;
  final int z = resetPatch ? 0 : v1.patch + patchInc;
  final Version v2 = Version(x, y, z);
  print('updating version from ${v1} to ${v2} ..');
  _writeVersionToPubspec(v2, pubspecFile);
  _writeVersionToSource(v2, versionFile);
}

/// Add all tasks from this package.
///
/// [cleanFunc] is an optional custom cleaner function used by [addCleanTask].
void addAllTasks({Function? cleanFunc}) {
  addUsageTask(asDefault: true);
  addTodosTask();
  addFixmesTask();
  addBumpVersionTasks();
  addFormatTask();
  addAnalyzeTask();
  addTestTask();
  addCleanTask(cleanFunc: cleanFunc);
  addCompileTask();
  //addDepLevelsTask();
  addDocumentTask();
  addBuildTask();
}

/// Add a safe default task to list all available tasks.
void addUsageTask({bool asDefault = true}) {
  void usageTaskFunction() {
    final List<GrinderTask> allTasks = context.grinder.tasks
      ..sort((GrinderTask a, GrinderTask b) => a.name.compareTo(b.name));
    const String defTag = ' (default)';
    final int longest =
        (defTag.length + allTasks.fold(0, (num v, GrinderTask e) => math.max(v, e.name.length)))
            .toInt();
    final Pubspec spec = _getPubSpec(_getPubspecFile(path_util.current));
    log(
      'grinder tasks for ${_getNameFromPubspec(pubspec: spec)} v${_getVersionFromPubspec(pubspec: spec)}',
    );
    log('');
    for (final GrinderTask task in allTasks) {
      final String name = '${task.name}${(task == defaultTask) ? defTag : ''}';
      log('${name.padRight(longest)}   ${task.description}');
    }
    log('');
    log('optional flags:');
    log('--verbose  log additional details when executing tasks');
  }

  final GrinderTask usage = GrinderTask(
    'usage',
    description: 'logs all available tasks',
    taskFunction: usageTaskFunction,
  );
  if (asDefault) {
    defaultTask = usage;
  } else {
    addTask(usage);
  }
}

void addTodosTask() {
  addTask(
    GrinderTask(
      'todo',
      description: 'lists lines of code containing TODOs',
      taskFunction: (_) => _showTokenInSource(<String>['TODO', ':'].join(''), context),
    ),
  );
}

void addFixmesTask() {
  addTask(
    GrinderTask(
      'fixme',
      description: 'lists lines of code containing FIXMEs',
      taskFunction: (_) => _showTokenInSource(<String>['FIXME', ':'].join(''), context),
    ),
  );
}

void addBumpVersionTasks() {
  final File pubspecFile = _getPubspecFile(path_util.current);
  final File versionFile = _getVersionFile(path_util.join(path_util.current, 'lib', 'src'));
  addTask(
    GrinderTask(
      'bump-major',
      description: 'bumps the major digit of the package version (X+1.0.0)',
      taskFunction: (_) =>
          _updateVersion(pubspecFile, versionFile, majorInc: 1, resetMinor: true, resetPatch: true),
    ),
  );
  addTask(
    GrinderTask(
      'bump-minor',
      description: 'bumps the minor digit of the package version (x.Y+1.0)',
      taskFunction: (_) => _updateVersion(pubspecFile, versionFile, minorInc: 1, resetPatch: true),
    ),
  );
  addTask(
    GrinderTask(
      'bump-patch',
      description: 'bumps the patch digit of the package version (x.y.Z+1)',
      taskFunction: (_) => _updateVersion(pubspecFile, versionFile, patchInc: 1),
    ),
  );
}

void addFormatTask() {
  addTask(
    GrinderTask(
      'format',
      description: 'formats dart source code',
      // DartFmt.format(existingSourceDirs, lineLength: 100);
      //   grind 0.9 is using deprecated dartfmt tool, needs to switch to dart format
      //   https://github.com/dart-lang/dart_style/issues/986
      taskFunction: (_) => run(
        'dart',
        arguments: <String>['format', '--output', 'write', '.'],
      ),
    ),
  );
}

void addAnalyzeTask() {
  void analyzeTaskFunction() {
    try {
      run(
        'dart',
        arguments: <String>['analyze'],
      );
    } on ProcessException {
      // the analyzer issues are already logged
      // check for fixes that could be auto-applied
      run(
        'dart',
        arguments: <String>['fix', '--dry-run'],
      );
      _fail('static analysis failed');
    }
  }

  addTask(
    GrinderTask(
      'analyze',
      description: 'performs static analysis of dart source code',
      //Analyzer.analyze(existingSourceDirs, fatalWarnings: true);
      //  regular dart command has better defaults and output formatting
      taskFunction: analyzeTaskFunction,
    ),
  );
}

void addTestTask() {
  void testTaskFunction() {
    try {
      run(
        'dart',
        arguments: <String>[
          'test',
          '--test-randomize-ordering-seed=random',
          '--reporter',
          'expanded',
        ],
      );
    } on ProcessException {
      // the unit test errors are already logged
      _fail('unit tests failed');
    }
  }

  addTask(
    GrinderTask(
      'test',
      description: 'runs unit tests',
      //TestRunner().test();
      //  grind-provided impl doesn't support randomization
      taskFunction: testTaskFunction,
    ),
  );
}

void addCleanTask({Function? cleanFunc}) {
  final Function selectedCleaner = cleanFunc ?? defaultClean;
  addTask(
    GrinderTask(
      'clean',
      description: 'deletes build artifacts',
      taskFunction: (_) => selectedCleaner(),
    ),
  );
}

void addCompileTask() {
  // check pubspec for executable names and skip if none
  final Map<String, String?> exeMap = _getExecutablesFromPubspec(
    pubspecFile: _getPubspecFile(path_util.current),
  );
  _hasExe = exeMap.isNotEmpty;

  if (!_hasExe) {
    return;
  }

  // FIXME: handle multiple executables
  final String exeKey = exeMap.keys.first;
  final String exeName = exeMap[exeKey] ?? exeKey;

  void compileTaskFunction() {
    final File pubspecFile = _getPubspecFile(path_util.current);
    final File versionFile = _getVersionFile(path_util.join(path_util.current, 'lib', 'src'));
    _syncVersionWithPubspec(versionFile, pubspecFile);

    final String ext = Platform.isWindows ? '.exe' : '';
    final String inPath = path_util.join(binDir.path, '${exeName}.dart');
    final String outPath = path_util.join(binDir.path, '${exeName}${ext}');
    run(
      'dart',
      arguments: <String>['compile', 'exe', '--output', outPath, inPath],
    );

    final String prompt = Platform.isWindows ? '>' : r'$';
    log('\nto run the new binary:\n${prompt} ${outPath}');
  }

  final GrinderTask compilation = GrinderTask(
    'compile',
    description: 'generates the executable binary',
    depends: <TaskInvocation>[TaskInvocation('clean')],
    taskFunction: compileTaskFunction,
  );
  addTask(compilation);
}

// disabled for now, lakos deps are holding back other libraries
//void addDepLevelsTask() {
//  void depLevelsTaskFunction() {
//    run(
//      'lakos',
//      arguments: <String>[
//        '--ignore',
//        '{test/**,tool/**}',
//        '.',
//        '|',
//        'dot',
//        '-Tsvg',
//        '-Gnewrank=true',
//        '-Gsplines=ortho',
//        '-Ecolor=#777',
//        '-Nfillcolor=#eee',
//        '-o',
//        'doc/levels.svg',
//      ],
//    );
//  }

//  addTask(
//    GrinderTask(
//      'levels',
//      description: 'generates dependency levels graph with lakos and dot (graphviz)',
//      taskFunction: depLevelsTaskFunction,
//    ),
//  );
//}

void addDocumentTask() {
  void documentTaskFunction() {
    if (_docDir.existsSync()) {
      delete(_docDir);
    }
    run(
      'dart',
      arguments: <String>['doc', '--validate-links', '.'],
    );
  }

  void docHostingFunction() {
    /* launching from grinder leaves a zombie process when trying to exit via CTRL-C
    try {
      // see: https://dart.dev/tools/dart-doc#view-local
      // win: tasklist /?
      //      tasklist /M dart*
      //      tskill <pid>
      run(
        'dart',
        arguments: ['pub', 'global', 'run', 'dhttpd', '--path', 'doc/api'],
      );
    } on ProcessException {
      // the dhttpd package maynot be installed
      _fail('local api hosting failed\nyou may need to install dhttpd:\ndart pub global activate dhttpd');
    }
    */
    log(
      '\nto host the api docs at http://localhost:8080/:\ndart pub global run dhttpd --path doc/api\n(CTRL-C to stop serving)',
    );
  }

  addTask(
    GrinderTask(
      'document',
      description: 'generates api docs',
      taskFunction: documentTaskFunction,
    ),
  );
  addTask(
    GrinderTask(
      'apidocs',
      description: 'hosts api docs for viewing at http://localhost:8080',
      taskFunction: docHostingFunction,
    ),
  );
}

void addBuildTask() {
  final List<TaskInvocation> deps = <TaskInvocation>[
    TaskInvocation('format'),
    TaskInvocation('analyze'),
    TaskInvocation('test'),
  ];
  if (_hasExe) {
    deps.add(TaskInvocation('compile'));
  }

  addTask(
    GrinderTask(
      'build',
      description: 'prepares a release candidate',
      depends: deps,
      taskFunction: (_) => log('did all the things!'),
    ),
  );
}
