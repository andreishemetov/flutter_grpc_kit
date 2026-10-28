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

See [`example/`](example/). From the repo root:

```bash
cd example && dart run bin/server.dart   # terminal 1
cd example && flutter run                # terminal 2
```

## Development

```bash
flutter pub get
flutter test
dart analyze
```

## License

MIT — see [LICENSE](LICENSE).
