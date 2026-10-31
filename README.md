# flutter_grpc_kit

Build application-friendly gRPC clients for Flutter without exposing generated
requests, responses, and stubs throughout the app.

The main abstraction is **`GrpcServiceClient<TStub>`**: extend it to wrap a
generated stub, expose methods shaped for your application, transform protobuf
responses, and return consistent `Result` values. Supporting building blocks
provide shared execution, channels, authentication, and logging:

- **`GrpcServiceClient`** — base class for generated stub wrappers
- **`GrpcExecutor`** — unary RPC helper with auth token metadata, response transformation, and single-flight token refresh on `UNAUTHENTICATED`
- **`GrpcChannelFactory`** / **`GrpcEndpoint`** — parse gateway URLs and own a shared `ClientChannel`
- **`GrpcLoggingInterceptor`** — PrettyDio-style boxed logs in debug

For [flutter_alice](https://pub.dev/packages/flutter_alice) network inspection, add [`grpc_alice_interceptor`](https://pub.dev/packages/grpc_alice_interceptor).

Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## Install

```yaml
dependencies:
  flutter_grpc_kit: ^0.1.0
  grpc: ^5.1.0
  protobuf: ^6.0.0
```

Optional Alice inspector:

```yaml
dependencies:
  grpc_alice_interceptor: ^0.1.1
  flutter_alice: ^2.0.1
```

From Git:

```yaml
dependencies:
  flutter_grpc_kit:
    git:
      url: https://github.com/andreishemetov/flutter_grpc_kit.git
      ref: v0.1.0
```

For local development, use a path dependency to this repo.

## Quick start

```dart
import 'package:flutter_grpc_kit/flutter_grpc_kit.dart';

final factory = GrpcChannelFactory(gatewayUrl: 'https://grpc.example.com');
final executor = GrpcExecutor(
  authHandler: myAuthHandler,
  metadata: {'x-app-version': '1.0.0'},
);

final interceptors = [
  GrpcLoggingInterceptor(),
];

final greeterClient = GreeterGrpcClient(
  channel: factory.channel,
  executor: executor,
  interceptors: interceptors,
);

final result = await greeterClient.sayHello(
  name: 'world',
);

result.fold(
  onSuccess: (value) => /* ... */,
  onFailure: (error) => /* ... */,
);
```

Define the application-facing client next to your networking layer:

```dart
final class GreeterGrpcClient extends GrpcServiceClient<GreeterClient> {
  GreeterGrpcClient({
    required super.channel,
    required super.executor,
    super.interceptors = const [],
    super.stub,
  }) : super(stubFactory: GreeterClient.new);

  Future<Result<String, Exception>> sayHello({required String name}) {
    return executor.run(
      (options) => stub.sayHello(
        HelloRequest(name: name),
        options: options,
      ),
      transform: (reply) => reply.message,
    );
  }
}
```

Only this class imports the generated request, response, and stub types. The
rest of the application works with `sayHello`, a `String`, and `Result`.
Implement **`AuthHandler`** in your app when authentication is required. Shared
headers can be supplied through `GrpcExecutor.metadata`.

## Example app

The [`example/`](example/) app demonstrates a concrete
[`GreeterGrpcClient`](example/lib/greeter_client.dart) and calls the public
[`hello.HelloService/SayHello`](https://grpcb.in/) API over TLS. From the repo
root:

```bash
cd example
flutter run
```

Tap **SayHello** to call `https://grpcb.in` on port 443. A successful request
with the default name displays `Reply: hello world`. Calls time out after 10
seconds instead of leaving the UI in a loading state. Use the network icon in
the app bar to inspect recorded calls with Alice.

The Android emulator must have working DNS. If it reports a
`Failed host lookup: 'grpcb.in'` error, cold-boot the emulator or launch it with
an explicit DNS server:

```bash
emulator -avd <your-avd-name> -dns-server 8.8.8.8
```

To use the optional local server instead, run `dart run bin/server.dart` from
the `example` directory and set the app endpoint to:

- `http://127.0.0.1:50051` on iOS Simulator or desktop
- `http://10.0.2.2:50051` on Android Emulator

## Development

```bash
flutter pub get
flutter test
dart analyze
cd example && flutter pub get && dart analyze && flutter test
```

Pull requests run the same checks via [GitHub Actions](.github/workflows/ci.yml). In branch protection, require **CI / analyze** (or **analyze**).

## License

MIT — see [LICENSE](LICENSE).
