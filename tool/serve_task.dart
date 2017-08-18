import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shelf/shelf.dart' show Handler, Request, Response;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_proxy/shelf_proxy.dart' show proxyHandler;

/// The port here is which port will be used to serve the app. Use this when
/// navigating to the app in the browser. Note that the port used for pub serve
/// will also work, but then non-fragmented routes ("deep-links") will 404.
const int defaultShelfPort = 8080;

/// The port to start pub serve on. This can be any high-numbered port.
const int defaultPubPort = 9100;

/// The hostname / interface to bind to. By default just bind to all
/// interfaces since this is the most convenient for developers.
const String defaultHostname = '0.0.0.0';

/// Any request hostname that should be redirected to localhost. This prevents
/// having to add localhost aliases as allowed origins with the IAM_HOST.
const Iterable<Pattern> localHostAliases = const ['0.0.0.0'];

String pubServeHost;
Handler pubServeProxy;

Future<Null> main(List<String> arguments) async {
  var parser = new ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Print help.')
    ..addFlag('force-poll',
        defaultsTo: true,
        help: 'Run "pub serve" with the --force-poll option. Disable this '
            'option when path dependencies are not being used to reduce CPU '
            'usage.',
        negatable: true)
    ..addFlag('no-pub-serve',
        defaultsTo: false, help: 'Do not run pub serve, only run the proxy.')
    ..addOption('port',
        abbr: 'p',
        defaultsTo: defaultShelfPort.toString(),
        help: 'Port on which to serve the application.')
    ..addOption('hostname',
        abbr: 'n',
        defaultsTo: defaultHostname,
        help: 'Hostname on which to serve the application and '
            'the pub serve process.')
    ..addOption('pub-serve-port',
        defaultsTo: defaultPubPort.toString(),
        help: 'Port to use for the pub serve process.')
    ..addOption('web-compiler',
        allowed: ['dart2js', 'dartdevc', 'none'],
        defaultsTo: 'none',
        help: 'The JavaScript compiler to use to serve the app.');
  var parsedArgs = parser.parse(arguments);

  if (parsedArgs['help']) {
    print('Tooling for running Wdesk SDK applications locally.\n');
    print(parser.usage);
    return;
  }

  var hostname = parsedArgs['hostname'];
  var forcePoll = parsedArgs['force-poll'];
  var pubPort = _parsePort(parsedArgs['pub-serve-port'], defaultPubPort);
  var shelfPort = _parsePort(parsedArgs['port'], defaultShelfPort);
  var webCompiler = parsedArgs['web-compiler'];

  if (pubPort == shelfPort) {
    print(_color(
        new AnsiPen()..red(),
        'Cannot use the same port for both pub serve ($pubPort)'
        'and the application ($shelfPort).'));
    return;
  }

  pubServeHost = 'http://$hostname:$pubPort';

  pubServeProxy = proxyHandler(pubServeHost);

  if (parsedArgs['no-pub-serve']) {
    // Exit early, do not start pub serve.
    startShelf(hostname, shelfPort);
    return;
  }

  print('Starting pub serve...');

  List<String> args = [
    'serve',
    '--hostname=$hostname',
    '--port=$pubPort',
    forcePoll ? '--force-poll' : '--no-force-poll',
  ];

  // Platform.version returns something like:
  // "1.24.1 (Wed Jun 14 07:48:25 2017) on "macos_x64"
  Version installedVersion = new Version.parse(Platform.version.split(' ')[0]);
  Version oneTwentyFour = new Version(1, 24, 0);

  // Dart 1.24.0 is the first version to support the web-compiler option.
  if (installedVersion >= oneTwentyFour) {
    args.add('--web-compiler=$webCompiler');
  }

  // Last argument is which directory to serve.
  args.add('example');

  // Start pub serve
  Process pubServe = await Process.start('pub', args);
  Completer c = new Completer();
  StreamSubscription stdoutSubscription = pubServe.stdout
      .transform(UTF8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
    // The output we get does not have ANSI color codes, because dart:io stdioType
    // is correctly determining that we are not a terminal.
    // There is no way to override this that I can tell.
    // FUTURE - we could mimic the color formatting that pub server has in
    // https://github.com/dart-lang/pub/blob/master/lib/src/command/serve.dart#L148
    // Provide pub serve output to the console
    print(line);
    // Lets the completer know when pub serve has begun serving
    if (line.startsWith('Build completed successfully') && !c.isCompleted) {
      c.complete();
    }
  });
  StreamSubscription stderrSubscription = pubServe.stderr
      .transform(UTF8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
    // Bail if pub serve encounters an error
    if (!c.isCompleted) {
      c.completeError(new PubServeException(line));
      return;
    }
    print(line);
  });
  try {
    // Wait for pub serve to begin serving before starting the proxy
    await c.future;

    startShelf(hostname, shelfPort);
  } on PubServeException catch (e) {
    await stdoutSubscription.cancel();
    await stderrSubscription.cancel();
    print(e);
  }
}

int _parsePort(String portString, int defaultPort) {
  int port = defaultPort;
  try {
    port = int.parse(portString);
  } catch (e) {
    print(_color(new AnsiPen()..red(),
        'Error parsing "$portString". Using default port: $defaultPort.'));
  }
  return port;
}

void startShelf(String hostname, int port) {
  print('Starting proxy...\n');
  print(_color(
      new AnsiPen()..green(), 'Serving app on:\t http://$hostname:$port\n'));
  shelf_io.serve(appHandler, hostname, port);
}

dynamic appHandler(Request request) {
  String path = request.url.path;

  // This prevents IAM_HOSTs from having to include all the permutations of
  // localhost aliases as allowed origins. All requests are redirected to the
  // assumed localhost hostname.
  if (localHostAliases
      .any((alias) => request.requestedUri.host.startsWith(alias))) {
    return new Response.seeOther(
        request.requestedUri.replace(host: 'localhost'));
  }
  // Return empty response for OAuth2 redirect uris.
  // Be sure to add any redirect uris used by experiences.
  if (path.startsWith('oauth2redirect') || path.startsWith('oauth.html')) {
    return new Response.ok('ok');
  }
  // Add anything that should not be rewritten to '/'
  // This should account for everything in the web/ directory
  if (!path.startsWith('packages/') &&
      !path.startsWith('js/') &&
      !path.startsWith('css/') &&
      !path.startsWith('prod/') &&
      !path.startsWith('sass/') &&
      !path.startsWith('dart_sdk.js') &&
      !path.startsWith('dart_stack_trace_mapper.js') &&
      !path.startsWith('require.js') &&
      !path.startsWith('rooter_example.dart.js') &&
      !path.startsWith('rooter_example.dart') &&
      !path.startsWith('service_worker.js') &&
      !path.startsWith('favicon.ico') &&
      !path.startsWith('browser-upgrade.html')) {
    // This is a view request, need to render index.html
    request = _copyRequest(request, request.requestedUri.replace(path: '/'));
  }
  return pubServeProxy(request);
}

Request _copyRequest(Request oldRequest, [Uri newPath]) {
  if (newPath == null) {
    newPath = oldRequest.url;
  }
  return new Request(oldRequest.method, newPath,
      protocolVersion: oldRequest.protocolVersion,
      headers: oldRequest.headers,
      body: oldRequest.read(),
      encoding: oldRequest.encoding,
      context: oldRequest.context);
}

class PubServeException implements Exception {
  String message;

  PubServeException(this.message);

  @override
  String toString() => 'Error starting pub serve: $message';
}

String _color(AnsiPen pen, String message) => pen(message);
