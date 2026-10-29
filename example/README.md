# flutter_grpc_kit example

Small Flutter app that wires up `GrpcChannelFactory`, `GrpcExecutor`, logging and Alice interceptors, and calls grpcb.in's `hello.HelloService/SayHello` RPC.

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
