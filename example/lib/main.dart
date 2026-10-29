import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_alice/alice.dart';
import 'package:flutter_grpc_kit/flutter_grpc_kit.dart';
import 'package:grpc_alice_interceptor/grpc_alice_interceptor.dart';

import 'greeter_client.dart';
import 'in_memory_auth_handler.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late final Alice _alice;
  late final InMemoryAuthHandler _auth;
  late final GrpcExecutor _executor;

  GrpcChannelFactory? _channelFactory;
  ExampleGreeterClient? _greeter;

  final _gatewayController = TextEditingController(
    text: 'https://grpcb.in',
  );
  final _nameController = TextEditingController(text: 'world');
  final _tokenController = TextEditingController(text: 'demo-token');

  String? _lastMessage;
  String? _lastError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _alice = Alice(
      showInspectorOnShake: true,
      // Alice's toast notifications require an OverlaySupport wrapper. The
      // inspector itself works through the navigator key without one.
      showNotification: false,
    );
    _auth = InMemoryAuthHandler(token: _tokenController.text);
    _executor = GrpcExecutor(
      authHandler: _auth,
      metadata: const {'x-example-app': 'flutter_grpc_kit_example'},
    );
    _rebuildClient();
  }

  @override
  void dispose() {
    _gatewayController.dispose();
    _nameController.dispose();
    _tokenController.dispose();
    unawaited(_channelFactory?.dispose());
    super.dispose();
  }

  void _rebuildClient() {
    unawaited(_channelFactory?.dispose());
    final factory = GrpcChannelFactory(
      gatewayUrl: _gatewayController.text.trim(),
    );
    final interceptors = <ClientInterceptor>[
      GrpcLoggingInterceptor(),
      GrpcAliceInterceptor(
        onCallRecorded: _alice.addHttpCall,
        serverHost: factory.endpoint.host,
        secure: factory.endpoint.useTls,
      ),
    ];
    _channelFactory = factory;
    _greeter = ExampleGreeterClient(
      channel: factory.channel,
      executor: _executor,
      interceptors: interceptors,
    );
  }

  Future<void> _sayHello() async {
    _auth.setToken(
      _tokenController.text.trim().isEmpty
          ? null
          : _tokenController.text.trim(),
    );
    setState(() {
      _loading = true;
      _lastMessage = null;
      _lastError = null;
    });

    _rebuildClient();
    final result = await _greeter!.sayHello(_nameController.text.trim());

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      result.fold(
        onSuccess: (message) => _lastMessage = message,
        onFailure: (error) => _lastError = error.toString(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final endpoint = _channelFactory?.endpoint;

    return MaterialApp(
      navigatorKey: _alice.getNavigatorKey(),
      title: 'flutter_grpc_kit example',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_grpc_kit'),
          actions: [
            IconButton(
              tooltip: 'Open Alice inspector',
              onPressed: _alice.showInspector,
              icon: const Icon(Icons.network_check),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _gatewayController,
              decoration: const InputDecoration(
                labelText: 'Gateway URL',
                helperText: 'Public grpcb.in TLS endpoint',
              ),
              onSubmitted: (_) => _rebuildClient(),
            ),
            const SizedBox(height: 12),
            if (endpoint != null)
              Text(
                'Endpoint: ${endpoint.host}:${endpoint.port} '
                '(${endpoint.useTls ? 'TLS' : 'insecure'})',
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Auth token (metadata key: token)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _sayHello,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('SayHello'),
            ),
            const SizedBox(height: 24),
            if (_lastMessage != null) SelectableText('Reply: $_lastMessage'),
            if (_lastError != null)
              SelectableText(
                'Error: $_lastError',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 24),
            const Text(
              'Calls hello.HelloService/SayHello on grpcb.in.\n\n'
              'Debug builds log gRPC calls to the console. '
              'Use the network icon or shake the device for Alice.',
            ),
          ],
        ),
      ),
    );
  }
}
