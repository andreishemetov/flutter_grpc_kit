---
name: flutter-grpc-kit
description: Use for any Dart or Flutter client-side gRPC work, whether creating a new integration or changing, extending, debugging, reviewing, or testing an existing one. Applies to .proto and .pbgrpc.dart files, generated stubs, typed clients, ClientChannel, interceptors, authentication, token refresh, response mapping, and gRPC tests. Prefer flutter_grpc_kit patterns when the package is already present or when reusable application-facing gRPC clients are wanted; do not use for non-Dart gRPC backends.
---

# Flutter gRPC Kit

Use this skill whenever a Dart or Flutter project contains or needs client-side
gRPC code. It covers both existing integrations and new services.

## Choose the mode

### Existing gRPC integration

Use this mode when the project already contains `.proto` or `.pbgrpc.dart`
files, generated stubs, `ClientChannel`, `ClientInterceptor`,
`GrpcServiceClient`, or `GrpcExecutor`.

- Inspect the current architecture before editing.
- Preserve existing public client APIs and dependency-injection conventions.
- Reuse the established channel, executor, interceptors, DTOs, and mappers.
- Make the smallest change needed for the requested service or behavior.
- Do not reinstall the package or rebuild working infrastructure.

### New gRPC integration

Use this mode when the project needs its first gRPC service or a new generated
service has not yet been wired into the application.

- Confirm that the task concerns a Dart or Flutter gRPC client, not a backend in
  another language.
- Locate the source `.proto` contract or existing generated Dart output.
- Add `flutter_grpc_kit` when it fits the user's requested architecture.
- Do not silently replace another established gRPC abstraction.
- Build the application-facing client and shared infrastructure described below.

## Workflow

1. Inspect the existing project structure, `pubspec.yaml`, and generated
   `.pbgrpc.dart` clients.
2. Follow the project's current DTO, mapping, dependency-injection, and testing
   conventions instead of introducing parallel abstractions.
3. If the package is absent and the task calls for it, add `flutter_grpc_kit`
   without changing unrelated dependencies.
4. Create an application-facing client that extends
   `GrpcServiceClient<TStub>`.
5. Keep generated requests, responses, and stubs inside that client.
6. Use `executor.run()` for unary RPCs and transform responses at the client
   boundary.
7. Reuse the application's shared channel, executor, and interceptor list.
8. Implement `AuthHandler` only when authentication is required; keep token
   persistence in the application.
9. Register the client with the project's existing dependency-injection style.
10. Add focused tests with an injected fake or mocked generated stub.
11. Run formatting, analysis, and the relevant tests.

Start from [the client template](assets/grpc_client.dart.template) and adapt its names,
request, response, and mapping to the target service. Use
[the auth handler template](assets/auth_handler.dart.template) only when the service
requires authentication.

## Boundaries

- Do not edit generated protobuf files manually.
- Do not expose generated protobuf messages to presentation code.
- Do not create a separate channel or executor for every client unless the
  application explicitly requires isolated connections or authentication.
- Do not duplicate token-refresh logic inside client methods.
- Do not invent a new DTO or mapping layer when the project already has one.
- Do not add streaming support through the unary executor; streaming calls need
  lifecycle-specific handling.
- Do not include credentials, private hosts, or proprietary service names in
  examples or tests.

## Package references

- https://pub.dev/packages/flutter_grpc_kit
- https://github.com/andreishemetov/flutter_grpc_kit
- https://github.com/andreishemetov/flutter_grpc_kit/tree/main/example
