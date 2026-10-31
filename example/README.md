# flutter_grpc_kit example

Small Flutter app showing how to put `GrpcServiceClient` between the UI and a
generated gRPC stub. `GreeterGrpcClient` exposes an application-friendly
`sayHello` method while keeping `HelloRequest`, `HelloReply`, and
`GreeterClient` out of the widget layer.

```text
ExampleApp -> GreeterGrpcClient -> generated GreeterClient -> grpcb.in
                    |
                    +-> shared GrpcExecutor
```

The app also demonstrates shared channel creation, authentication metadata,
logging, and Alice inspection. The central example is
[`lib/greeter_client.dart`](lib/greeter_client.dart):

```dart
final class GreeterGrpcClient extends GrpcServiceClient<GreeterClient> {
  GreeterGrpcClient({
    required super.channel,
    required super.executor,
    super.interceptors = const [],
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

The widget constructs this client once per endpoint and calls only its public
API. It never constructs protobuf messages or invokes the generated stub.

## Run

1. Run the Flutter app (simulator/emulator or device):

   ```bash
   flutter run
   ```

2. Tap **SayHello**. The default endpoint is grpcb.in over TLS. Open the Alice inspector from the app bar (or shake on a physical device).

### Gateway URL tips

| Target | URL |
|--------|-----|
| Public grpcb.in service | `https://grpcb.in` (port 443) |
| iOS Simulator / desktop | `http://127.0.0.1:50051` |
| Android emulator | `http://10.0.2.2:50051` |

The localhost URLs require the optional sample server: `dart run bin/server.dart`.

Protos live under `protos/`. Generated stubs are in `lib/src/generated/`. Regenerate with `protoc` and `protoc_plugin` if you change the `.proto` file.
