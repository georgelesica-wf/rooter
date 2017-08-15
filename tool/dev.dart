import 'package:dart_dev/dart_dev.dart'
    show dev, config, TestRunnerConfig, Environment;

main(List<String> args) async {
  // https://github.com/Workiva/dart_dev

  config.analyze.entryPoints = [
    'lib/rooter.dart',
    'tool/dev.dart',
  ];

  config.coverage.pubServe = true;

  config.format
    ..paths = [
      'example/',
      'lib/',
      'tool/',
    ];

//  config.genTestRunner.configs = <TestRunnerConfig>[
//    new TestRunnerConfig(
//        directory: 'test/unit/vm',
//        env: Environment.vm,
//        filename: 'generated_runner_test'),
//    new TestRunnerConfig(
//        genHtml: true,
//        directory: 'test/unit/browser',
//        env: Environment.browser,
//        filename: 'generated_runner_test',
//        dartHeaders: const <String>[
//          "import 'package:react/react_client.dart';",
//          "import 'package:web_skin_dart/ui_core.dart';"
//        ],
//        preTestCommands: const <String>[
//          'setClientConfiguration();',
//          'enableTestMode();'
//        ],
//        htmlHeaders: const <String>[
//          '<script src="packages/react/react_with_addons.js"></script>',
//          '<script src="packages/react/react_dom.js"></script>'
//        ])
//  ];
//
//  config.test
//    ..pubServe = true
//    ..platforms = ['content-shell', 'vm']
//    ..unitTests = [
//      'test/unit/browser/generated_runner_test.dart',
//      'test/unit/vm/generated_runner_test.dart'
//    ];
//
//  config.taskRunner.tasksToRun = [
//    'pub run dart_dev analyze',
//    'pub run over_react_format:bootstrap --check',
//    'pub run dart_dev format --check',
//    'pub run dart_dev gen-test-runner --check',
//    './tool/verify_sass.sh',
//    'pub run dart_dev test',
//    'pub run dart_dev coverage --no-html',
//    './tool/tagged_build.sh',
//  ];

  config.local..executables['py'] = ['python'];

  await dev(args);
}
