# flutter_grpc_kit agent instructions

## Purpose

`flutter_grpc_kit` helps Flutter applications build typed, application-facing
gRPC clients around generated Dart stubs.

The primary abstraction is `GrpcServiceClient<TStub>`. `GrpcExecutor`,
`GrpcChannelFactory`, authentication, and interceptors support those clients.

## Architecture

- Keep generated protobuf requests, responses, and stubs inside gRPC clients.
- Application-facing clients extend `GrpcServiceClient<TStub>`.
- Execute unary RPCs through `GrpcExecutor`.
- Transform generated responses into application DTOs or existing Dart types.
- Return `Result<T, Exception>` from application-facing client methods.
- Reuse a shared `ClientChannel`, `GrpcExecutor`, and interceptor list.
- Keep token storage application-owned through `AuthHandler`.
- Preserve single-flight token refresh behavior.
- Do not edit generated protobuf files manually.

## Public API

- Treat exports from `lib/flutter_grpc_kit.dart` as public API.
- Avoid breaking public constructors, methods, and typedefs in patch releases.
- Update `README.md`, `CHANGELOG.md`, and the example when usage changes.
- Keep examples free of private hosts, credentials, and proprietary service names.

## Verification

Run from the repository root:

```bash
flutter pub get
dart format --set-exit-if-changed .
dart analyze
flutter test
cd example && flutter pub get && dart analyze && flutter test
```

Before publishing, also run:

```bash
dart pub publish --dry-run
```
