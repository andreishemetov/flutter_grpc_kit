# flutter_grpc_kit

Reusable gRPC building blocks for Flutter apps:

- **`GrpcExecutor`** — unary RPC helper with auth token metadata, optional extra headers, and single-flight token refresh on `UNAUTHENTICATED`
- **`GrpcChannelFactory`** / **`GrpcEndpoint`** — parse gateway URLs and own a `ClientChannel`
- **`GrpcServiceClient`** — base class for generated stub wrappers
- **`GrpcLoggingInterceptor`** — PrettyDio-style boxed logs in debug

For [flutter_alice](https://pub.dev/packages/flutter_alice) network inspection, add the sibling package [`grpc_alice_interceptor`](../grpc_alice_interceptor).

## Install

### From GitHub (private or public)

```yaml
dependencies:
  flutter_grpc_kit:
    git:
      url: https://github.com/andreishemetov/flutter_grpc_kit.git
      ref: v0.1.0 # tag or branch
```

### Local path (monorepo sibling)

```yaml
dependencies:
  flutter_grpc_kit:
    path: ../flutter_grpc_kit
```

Then run `flutter pub get`.

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

// Pass interceptors when constructing generated clients:
// MyServiceClient(factory.channel, interceptors: interceptors);

final result = await executor.run<MyEntity, MyResponse>(
  (options) => client.getSomething(request, options: options),
  transform: MyEntity.fromResponse,
);

result.fold(
  onSuccess: (value) => /* ... */,
  onFailure: (error) => /* ... */,
);
```

Implement **`AuthHandler`** in your app. Pass extra per-call headers via `GrpcExecutor.metadata`.

## Example app

The [`example/`](example/) app calls the public
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
```

## License

MIT — see [LICENSE](LICENSE).
