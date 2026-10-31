# Building reusable gRPC clients for Flutter

Have you ever searched for a convenient way to organize gRPC clients in a growing Flutter application?

When working with REST APIs, we have Dio and a large ecosystem of packages built around it. They provide reusable clients, interceptors, response transformation, unified error handling, authentication, token refresh, and retries.

While looking for a similar solution for gRPC, I found the official [`grpc`](https://pub.dev/packages/grpc) package. It provides the essential transport, generated stubs, interceptors, metadata, and call options.

I also found [`fresh_grpc`](https://pub.dev/documentation/fresh_grpc/latest/), which focuses on authentication, token refresh, and retrying unary calls.

However, I could not find a complete solution for building reusable application-level clients around generated gRPC stubs.

I wanted each client to:

- Expose an API that is convenient for the application.
- Hide generated request and response types where possible.
- Transform protobuf responses into application DTOs.
- Return consistent success and failure results.
- Reuse the same channel, executor, authentication, and interceptors.
- Support automatic token refresh.
- Be easy to replace or test.
- Scale together with the application.

So I decided to create [`flutter_grpc_kit`](https://pub.dev/packages/flutter_grpc_kit).

Let’s take a closer look at the problem it solves.

## Generated stubs are not application clients

After generating Dart code from a Protocol Buffer definition, we receive a client stub:

```dart
final response = await generatedClient.getProfile(
  GetProfileRequest(
    userId: userId,
  ),
  options: CallOptions(
    metadata: {
      'token': accessToken,
      'x-app-version': '1.0.0',
    },
  ),
);
```

This works, but the application now needs to understand:

- Which generated client should be used.
- Which protobuf request should be created.
- Which metadata must be attached.
- How the generated response should be transformed.
- How `GrpcError` should be handled.
- What should happen if the access token has expired.

The generated stub represents the backend contract. It does not necessarily provide the API we want to use throughout the application.

For example, instead of exposing this:

```dart
ResponseFuture<GetProfileResponse> getProfile(
  GetProfileRequest request, {
  CallOptions? options,
});
```

I would prefer the application to use this:

```dart
Future<Result<ProfileDto, Exception>> getProfile({
  required int userId,
});
```

The generated request, response, metadata, and transport details should remain inside a dedicated client.

## Creating an application-level gRPC client

This is the main idea behind `GrpcServiceClient<TStub>`.

It provides shared wiring for a generated stub:

```dart
abstract base class GrpcServiceClient<TStub> {
  GrpcServiceClient({
    required ClientChannel channel,
    required GrpcExecutor executor,
    GrpcClientInterceptors interceptors = const [],
    TStub? stub,
    required GrpcStubFactory<TStub> stubFactory,
  });

  @protected
  GrpcExecutor get executor;

  @protected
  TStub get stub;
}
```

A concrete client extends `GrpcServiceClient` and specifies its generated stub type:

```dart
final class ProfileGrpcClient
    extends GrpcServiceClient<ProfileServiceClient> {
  ProfileGrpcClient({
    required super.channel,
    required super.executor,
    super.interceptors,
    super.stub,
  }) : super(
          stubFactory: ProfileServiceClient.new,
        );
}
```

The base class creates the generated stub using:

- The shared `ClientChannel`.
- The configured interceptors.
- The provided stub factory.

The concrete client receives protected access to `stub` and `executor`.

Now we can add application-friendly methods.

## Hiding generated requests and responses

Let’s add a method for loading a profile:

```dart
final class ProfileGrpcClient
    extends GrpcServiceClient<ProfileServiceClient> {
  ProfileGrpcClient({
    required super.channel,
    required super.executor,
    super.interceptors,
    super.stub,
  }) : super(
          stubFactory: ProfileServiceClient.new,
        );

  Future<Result<ProfileDto, Exception>> getProfile({
    required int userId,
  }) {
    return executor.run(
      (options) => stub.getProfile(
        GetProfileRequest(
          userId: Int64(userId),
        ),
        options: options,
      ),
      transform: (response) => response.toDto(),
    );
  }
}
```

The rest of the application does not need to create `GetProfileRequest` or work with `GetProfileResponse`.

It simply calls:

```dart
final result = await profileGrpcClient.getProfile(
  userId: userId,
);
```

The client becomes a boundary between generated transport code and the rest of the application.

It knows how to:

- Create the protobuf request.
- Call the correct generated method.
- Pass the prepared `CallOptions`.
- Transform the response.
- Return a consistent result.

This is the most important part of the package.

`GrpcExecutor`, channel factory, authentication, and interceptors support the client, but the client exposes the API used by the application.

## Using a generic executor inside the client

Although the client is the main abstraction, we still need a reusable way to execute its methods.

Without a shared executor, every client would repeat the same code:

```dart
try {
  final response = await stub.getProfile(
    request,
    options: createCallOptions(),
  );

  return Success(response.toDto());
} on GrpcError catch (error) {
  return Failure(error);
} on Exception catch (error) {
  return Failure(error);
}
```

We would also need to repeat authentication, token refresh, and retry behavior.

`GrpcExecutor` centralizes this execution flow:

```dart
final result = await executor.run<ProfileDto, GetProfileResponse>(
  (options) => stub.getProfile(
    request,
    options: options,
  ),
  transform: (response) => response.toDto(),
);
```

The two generic types have different responsibilities:

- `GetProfileResponse` is the generated transport response.
- `ProfileDto` is the value returned by our client.

The executor accepts the RPC call, builds its `CallOptions`, executes the request, applies the transformation, and returns a `Result`.

This gives every custom client the same execution behavior.

## Handling the result

The calling layer receives a predictable result:

```dart
final result = await profileGrpcClient.getProfile(
  userId: userId,
);

result.fold(
  onSuccess: (profile) {
    // Update the application state.
  },
  onFailure: (error) {
    // Map the error to the appropriate state.
  },
);
```

The calling code does not need to catch transport exceptions directly.

It also does not need to know whether the request was retried after authentication was refreshed.

That responsibility remains inside the networking layer.

## One client can wrap multiple related stubs

A custom client is not required to wrap exactly one generated service.

Sometimes a backend capability is split across several related gRPC services. From the application’s perspective, however, those operations belong together.

For example, a catalog feature may use three generated stubs:

- `CatalogServiceClient`.
- `FavoritesServiceClient`.
- `RecommendationsServiceClient`.

We can expose them through one application-level client:

```dart
final class CatalogGrpcClient
    extends GrpcServiceClient<CatalogServiceClient> {
  CatalogGrpcClient({
    required super.channel,
    required super.executor,
    super.interceptors,
    super.stub,
    FavoritesServiceClient? favoritesStub,
    RecommendationsServiceClient? recommendationsStub,
  }) : _favoritesStub =
           favoritesStub ??
           FavoritesServiceClient(
             channel,
             interceptors: interceptors,
           ),
       _recommendationsStub =
           recommendationsStub ??
           RecommendationsServiceClient(
             channel,
             interceptors: interceptors,
           ),
       super(
         stubFactory: CatalogServiceClient.new,
       );

  final FavoritesServiceClient _favoritesStub;
  final RecommendationsServiceClient _recommendationsStub;

  Future<Result<List<ProductDto>, Exception>> getProducts() {
    return executor.run(
      (options) => stub.getProducts(
        GetProductsRequest(),
        options: options,
      ),
      transform: (response) {
        return response.products
            .map((product) => product.toDto())
            .toList(growable: false);
      },
    );
  }

  Future<Result<void, Exception>> addToFavorites({
    required int productId,
  }) {
    return executor.run<void, AddFavoriteResponse>(
      (options) => _favoritesStub.add(
        AddFavoriteRequest(
          productId: Int64(productId),
        ),
        options: options,
      ),
      transform: (_) {},
    );
  }

  Future<Result<List<ProductDto>, Exception>>
      getRecommendations() {
    return executor.run(
      (options) => _recommendationsStub.getRecommended(
        GetRecommendedRequest(),
        options: options,
      ),
      transform: (response) {
        return response.products
            .map((product) => product.toDto())
            .toList(growable: false);
      },
    );
  }
}
```

The rest of the application works with one `CatalogGrpcClient`.

It does not need to know how many generated services are involved.

This makes the client an API around an application capability rather than a simple one-to-one wrapper around a generated class.

## Making clients easier to test

The base client accepts an optional generated stub:

```dart
ProfileGrpcClient({
  required super.channel,
  required super.executor,
  super.interceptors,
  super.stub,
}) : super(
       stubFactory: ProfileServiceClient.new,
     );
```

In production, the stub is created from the channel.

In tests, a fake or mocked stub can be injected:

```dart
final client = ProfileGrpcClient(
  channel: channel,
  executor: executor,
  stub: mockProfileServiceClient,
);
```

This makes it possible to test:

- Request construction.
- Response transformation.
- Empty or invalid payload handling.
- Success results.
- Transport errors.
- Application-specific client behavior.

We do not need a real backend connection to test the client’s mapping logic.

## Creating a channel with `GrpcChannelFactory`

Now let’s prepare the shared networking infrastructure.

First, we create `GrpcChannelFactory`:

```dart
final channelFactory = GrpcChannelFactory(
  gatewayUrl: 'https://grpc.example.com',
);
```

The factory parses the gateway URL and selects the appropriate channel credentials.

For an HTTPS endpoint:

```dart
GrpcChannelFactory(
  gatewayUrl: 'https://grpc.example.com',
);
```

it creates a secure channel using TLS.

For a local HTTP endpoint:

```dart
GrpcChannelFactory(
  gatewayUrl: 'http://10.0.2.2:50051',
);
```

it creates an insecure channel with the specified port.

The parsed endpoint is available through the factory:

```dart
print(channelFactory.endpoint.host);
print(channelFactory.endpoint.port);
print(channelFactory.endpoint.useTls);
```

The channel is created lazily when it is first accessed:

```dart
final channel = channelFactory.channel;
```

The factory owns the channel, so it should also dispose of it:

```dart
await channelFactory.dispose();
```

In a real application, the factory would usually be registered as a singleton in the dependency-injection container.

## Adding interceptors

Interceptors can also be created once and shared by every custom client:

```dart
final interceptors = <ClientInterceptor>[
  GrpcLoggingInterceptor(),
];
```

`GrpcLoggingInterceptor` prints readable information about gRPC requests, responses, errors, metadata, and execution time during development.

The interceptors are independent of the executor.

The executor controls authentication, response transformation, retry, and result handling. Interceptors observe calls at the generated stub level.

This means we can change the interceptor configuration without changing our custom clients.

## Handling authentication

Every application stores and refreshes its credentials differently. For this reason, `flutter_grpc_kit` does not manage token storage itself.

Instead, the application implements `AuthHandler`:

```dart
final class AppAuthHandler implements AuthHandler {
  AppAuthHandler({
    String? token,
  }) : _token = token;

  String? _token;

  @override
  String? getToken() {
    return _token;
  }

  @override
  Future<String?> refreshToken() async {
    final newToken = await requestNewAccessToken();

    _token = newToken;
    return newToken;
  }

  @override
  void clearToken() {
    _token = null;
  }
}
```

The implementation can use secure storage, an authentication repository, or any other mechanism used by the application.

We then pass it to the shared executor:

```dart
final authHandler = AppAuthHandler(
  token: storedAccessToken,
);

final executor = GrpcExecutor(
  authHandler: authHandler,
  metadata: const {
    'x-app-version': '1.0.0',
    'x-platform': 'flutter',
  },
);
```

The executor adds the shared metadata and current token to every call.

It can also be created without an authentication handler for public services:

```dart
final executor = GrpcExecutor(
  metadata: const {
    'x-app-version': '1.0.0',
  },
);
```

## Handling concurrent token refresh

Imagine that several custom clients start requests at the same time:

```text
ProfileGrpcClient.getProfile()
CatalogGrpcClient.getProducts()
MessagesGrpcClient.getMessages()
```

If the access token has expired, all requests may receive `UNAUTHENTICATED`.

A simple implementation could start several refresh operations:

```text
Request A ── UNAUTHENTICATED ── refreshToken()
Request B ── UNAUTHENTICATED ── refreshToken()
Request C ── UNAUTHENTICATED ── refreshToken()
```

This may cause race conditions, especially when the backend rotates refresh tokens.

`GrpcExecutor` uses a single-flight refresh approach instead.

The first failed request starts the refresh. Other requests wait for the same operation:

```text
Request A ── starts token refresh ─────────────┐
Request B ── waits for the current refresh ────┼── retry
Request C ── waits for the current refresh ────┘
```

After the token is refreshed, the requests retry using the new authentication data.

The clients do not need to coordinate this process. They all reuse the same executor.

## Connecting everything

Now we can create the complete networking layer:

```dart
final channelFactory = GrpcChannelFactory(
  gatewayUrl: 'https://grpc.example.com',
);

final authHandler = AppAuthHandler(
  token: storedAccessToken,
);

final executor = GrpcExecutor(
  authHandler: authHandler,
  metadata: const {
    'x-app-version': '1.0.0',
  },
);

final interceptors = <ClientInterceptor>[
  GrpcLoggingInterceptor(),
];

final profileClient = ProfileGrpcClient(
  channel: channelFactory.channel,
  executor: executor,
  interceptors: interceptors,
);

final catalogClient = CatalogGrpcClient(
  channel: channelFactory.channel,
  executor: executor,
  interceptors: interceptors,
);

final messagesClient = MessagesGrpcClient(
  channel: channelFactory.channel,
  executor: executor,
  interceptors: interceptors,
);
```

The structure looks like this:

```text
Application
     │
     ├── ProfileGrpcClient
     ├── CatalogGrpcClient
     └── MessagesGrpcClient
              │
              ├── generated stubs
              ├── shared GrpcExecutor
              ├── shared ClientChannel
              └── shared interceptors
```

All clients share:

- One channel.
- One executor.
- One authentication strategy.
- One coordinated token-refresh operation.
- One interceptor configuration.
- One approach to success and failure handling.

Each client only contains the requests, transformations, and methods related to its own application capability.

## Registering clients with dependency injection

In a larger application, the shared infrastructure and custom clients can be registered once:

```dart
getIt.registerLazySingleton<GrpcChannelFactory>(
  () => GrpcChannelFactory(
    gatewayUrl: grpcGatewayUrl,
  ),
);

getIt.registerLazySingleton<GrpcExecutor>(
  () => GrpcExecutor(
    authHandler: getIt<AuthHandler>(),
    metadata: const {
      'x-app-version': '1.0.0',
    },
  ),
);

getIt.registerLazySingleton<GrpcClientInterceptors>(
  () => [
    GrpcLoggingInterceptor(),
  ],
);

getIt.registerLazySingleton<ProfileGrpcClient>(
  () => ProfileGrpcClient(
    channel: getIt<GrpcChannelFactory>().channel,
    executor: getIt<GrpcExecutor>(),
    interceptors: getIt<GrpcClientInterceptors>(),
  ),
);

getIt.registerLazySingleton<CatalogGrpcClient>(
  () => CatalogGrpcClient(
    channel: getIt<GrpcChannelFactory>().channel,
    executor: getIt<GrpcExecutor>(),
    interceptors: getIt<GrpcClientInterceptors>(),
  ),
);
```

A repository or another data-layer component receives only the client it needs:

```dart
final class ProfileRepository {
  ProfileRepository({
    required ProfileGrpcClient client,
  }) : _client = client;

  final ProfileGrpcClient _client;

  Future<Result<ProfileDto, Exception>> getProfile({
    required int userId,
  }) {
    return _client.getProfile(
      userId: userId,
    );
  }
}
```

The repository does not create channels, generated stubs, call options, or interceptors.

It depends on an application-level client with a clear API.

## Why I published `flutter_grpc_kit`

The official Dart `grpc` package provides the essential foundation for channels, generated stubs, metadata, call options, and interceptors.

`flutter_grpc_kit` does not replace it. It is built on top of it.

Its main purpose is to make it easier to build custom, reusable clients around generated gRPC code.

Those clients:

- Expose application-friendly methods.
- Hide protobuf request construction.
- Transform generated responses.
- Return consistent results.
- Reuse the same executor and networking infrastructure.
- Support authentication and coordinated token refresh.
- Accept shared interceptors.
- Can be tested with injected stubs.
- Scale without duplicating request-handling code.

The result is a networking layer that can grow together with the application.

Adding another backend service does not require rebuilding the infrastructure. We create a typed client, provide its generated stub factory, add application-friendly methods, and reuse everything else.

To install the package, run:

```bash
flutter pub add flutter_grpc_kit
```

The repository also contains an example that calls the public [`grpcb.in`](https://grpcb.in/) `hello.HelloService/SayHello` API over TLS.

Useful links:

- [`flutter_grpc_kit` on pub.dev](https://pub.dev/packages/flutter_grpc_kit)
- [Source code on GitHub](https://github.com/andreishemetov/flutter_grpc_kit)
- [Example application](https://github.com/andreishemetov/flutter_grpc_kit/tree/main/example)
- [Official Dart gRPC package](https://pub.dev/packages/grpc)

## What comes next?

Alice is a useful in-app network inspector for Flutter applications. It allows developers and testers to inspect HTTP requests and responses without connecting the device to an external proxy.

However, gRPC calls are not recorded by Alice out of the box.

For this reason, I created [`grpc_alice_interceptor`](https://pub.dev/packages/grpc_alice_interceptor), which adds gRPC call inspection to the Alice interface.

I will cover this package, its implementation, and the complete setup in my next article.

That’s it for now! I tried to keep things as clear and practical as possible, and I hope you learned something new or useful.

Let me know what you think. If you spot anything that could be improved, or if you use a different approach for organizing gRPC clients in Flutter, feel free to drop a comment!
