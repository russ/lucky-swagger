# lucky-swagger

[![CI](https://github.com/marmaxev/lucky-swagger/actions/workflows/ci.yml/badge.svg)](https://github.com/marmaxev/lucky-swagger/actions/workflows/ci.yml)

Automatic OpenAPI 3.0 documentation for [Lucky](https://luckyframework.org) apps. A typical CRUD action needs **zero annotations** to produce a correct, complete spec.

## Philosophy

Most OpenAPI generators require annotating every endpoint. lucky-swagger flips this: inference handles the 80% case, annotations handle the rest.

```crystal
# Zero annotations — the generator infers:
# - route path and method (from Lucky's router)
# - security (from your auth mixin)
# - request body (from SaveUser operation by convention)
# - 201 response + UserSerializer schema
# - auto-422 for validation errors
class Api::Users::Create < ApiAction
  post "/api/users" do
    json user, status: 201
  end
end
```

Add annotations when you need to override or enrich — never because the tool demands it.

## Installation

```yaml
# shard.yml
dependencies:
  lucky-swagger:
    github: marmaxev/lucky-swagger
```

```bash
shards install
```

```crystal
# src/app.cr
require "lucky-swagger"
```

## Quick Start

### 1. Configure

```crystal
LuckySwagger.configure do |settings|
  settings.title       = "My API"
  settings.description = "API documentation"
  settings.version     = "1.0.0"
  settings.servers     = [{url: "https://api.example.com", description: "Production"}]
end
```

### 2. Enable SwaggerUI

```crystal
# src/app_server.cr
class AppServer < Lucky::BaseAppServer
  def middleware : Array(HTTP::Handler)
    [
      Lucky::LogHandler.new,
      LuckySwagger::Handlers::WebHandler.new(swagger_url: "/api-docs"),
      Lucky::ErrorHandler.new(action: Errors::Show),
      Lucky::RouteHandler.new,
    ] of HTTP::Handler
  end
end
```

Use `live: true` for hot-reload in development (spec regenerates on every request, no file needed):

```crystal
LuckySwagger::Handlers::WebHandler.new(swagger_url: "/api-docs", live: true)
```

### 3. Include Documentable in serializers

```crystal
struct UserSerializer < BaseSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    property id         : Int64
    property email      : String
    property name       : String
    property created_at : Time
  end
end
```

### 4. Generate the spec

```bash
lucky lucky_swagger.generate_open_api            # writes swagger/api.yaml
lucky lucky_swagger.generate_open_api -F json    # writes swagger/api.json
lucky lucky_swagger.generate_open_api --validate # validates structure + refs
```

---

## What you get for free

### Auth mixin → security (IR-1)

Map your auth mixins to security scheme names once in config:

```crystal
settings.auth_mixin_map = {
  "Api::Auth::RequireAuthToken" => "bearerAuth",
}
```

Every action that `include`s that mixin gets `security: [{bearerAuth: []}]` automatically. Override per-action with `@[Endpoint(security: "none")]` for public endpoints.

### SaveOperation → request body (IR-2)

`Api::Posts::Create` and `Api::Posts::Update` automatically bind to a top-level `SavePost` operation. Define the operation's schema once:

```crystal
class SavePost
  include LuckySwagger::Documentable

  swagger_fields do
    field title : String, max_length: 200
    field status : String, enum: ["draft", "published"], default: "draft"
    field body : String
  end
end
```

Both `Create` and `Update` reference this schema without any annotation.

### Serializer → 200/201 response (IR-3)

`Api::Posts::Show`, `Api::Posts::Create`, and `Api::Posts::Update` automatically infer the response from `PostSerializer` (singularized from the `Posts` namespace). Create gets 201, Show/Update get 200. Write actions include an auto-422.

### Index → paginated collection (IR-4)

`Api::Posts::Index` automatically infers a paginated collection response: `{items: [PostSerializer], pagination: Pagination}`.

### Tags from namespace (IR-8)

`Api::V1::Frontend::Users::Index` becomes tag `"Frontend > Users"` after stripping configured prefixes. Configurable via `tag_strip_prefixes`, `tag_separator`, and `default_tag`.

---

## Annotations

Annotations are overrides over inference — never required for the common path.

### @[LuckySwagger::Endpoint]

```crystal
@[LuckySwagger::Endpoint(
  summary:      "Create a post",
  description:  "Creates a draft post for the authenticated user.",
  tags:         ["Posts"],
  security:     "bearerAuth",   # "none" for public
  deprecated:   true,
  external_docs: {url: "https://docs.example.com/posts", description: "Post API docs"},
  servers:      [{url: "https://upload.example.com", description: "Upload node"}],
)]
```

### @[LuckySwagger::Response]

```crystal
# Serializer (infers $ref to components/schemas)
@[LuckySwagger::Response(200, serializer: UserSerializer)]
@[LuckySwagger::Response(200, serializer: UserSerializer, collection: true)]

# Direct schema struct
@[LuckySwagger::Response(201, schema: UserCreatedResponse, description: "Created")]

# Polymorphic
@[LuckySwagger::Response(200, one_of: [CatResponse, DogResponse])]
@[LuckySwagger::Response(200, any_of: [CatResponse, DogResponse], discriminator: "kind")]
@[LuckySwagger::Response(200, all_of: [BaseResponse, ExtensionResponse])]

# Non-JSON content types
@[LuckySwagger::Response(200, content_type: "text/csv", description: "CSV export")]
@[LuckySwagger::Response(200, content_type: "application/pdf")]

# With example
@[LuckySwagger::Response(200, serializer: UserSerializer, example: {id: 1, name: "Alice"})]

# Error / no-content
@[LuckySwagger::Response(422, schema: LuckySwagger::ErrorSchema, description: "Validation failed")]
@[LuckySwagger::Response(204)]
```

Stack multiple `@[Response]` annotations for multiple status codes.

### @[LuckySwagger::RequestBody]

```crystal
# JSON schema
@[LuckySwagger::RequestBody(schema: UserCreateRequest)]

# Multipart / file upload
@[LuckySwagger::RequestBody(multipart: {avatar: File, display_name: String})]
```

`File` fields get `type: string, format: binary`.

### @[LuckySwagger::HeaderParam] / @[LuckySwagger::CookieParam]

Stackable. Both support `name`, `type`, `required`, `description`.

```crystal
@[LuckySwagger::HeaderParam(name: "X-Request-ID", type: String, required: false, description: "Trace ID")]
@[LuckySwagger::HeaderParam(name: "Authorization", type: String, required: true)]
@[LuckySwagger::CookieParam(name: "session_id", type: String, required: true)]
```

Supported types: `String`, `Int32`, `Int64`, `Float32`, `Float64`, `Bool`.

### @[LuckySwagger::Operation]

Override the SaveOperation convention binding for a specific action:

```crystal
@[LuckySwagger::Operation(SaveCustomThing)]
class Api::Things::Update < ApiAction
  # ...
end
```

---

## Schema definition

### swagger_fields with field macro

The `field` macro extends `property` with inline OpenAPI constraints:

```crystal
struct PostSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    property id : Int64   # plain property — no constraints

    field title       : String,  max_length: 200, min_length: 1
    field status      : String,  enum: ["draft", "published"], default: "draft"
    field author_email: String,  format: "email"
    field priority    : Int32,   minimum: 1, maximum: 10, default: 5
    field score       : Float64, minimum: 0.0, maximum: 100.0
    field published_at: String?, format: "date-time"

    # With example
    @[LuckySwagger::FieldMeta(example: "alice@example.com")]
    property email : String
  end
end
```

Constraint kwargs: `max_length` → `maxLength`, `min_length` → `minLength`, `minimum`, `maximum`, `enum`, `default`, `format`, `example`.

Plain `property` still works for unconstrained fields. Nilable fields (`T?`) are excluded from the `required` array automatically.

### @[LuckySwagger::ScalarFormat]

Mark custom scalar types with their OpenAPI representation:

```crystal
@[LuckySwagger::ScalarFormat(type: "string", format: "uuid")]
struct UUID
  # ...
end
```

The introspector emits the correct type/format wherever this type appears as a schema property.

---

## Configuration reference

```crystal
LuckySwagger.configure do |settings|
  # API info
  settings.title            = "My API"
  settings.description      = "Full API documentation"
  settings.version          = "1.0.0"
  settings.terms_of_service = "https://example.com/tos"
  settings.contact          = {name: "Support", email: "support@example.com", url: nil}
  settings.license          = {name: "MIT", url: "https://opensource.org/licenses/MIT"}

  # Servers
  settings.servers = [
    {url: "http://localhost:5000", description: "Development"},
    {url: "https://api.example.com", description: "Production"},
  ]

  # Route filtering
  settings.include_routes = :all        # default
  settings.include_routes = :api_only   # paths containing "api"
  settings.include_routes = /^\/api\//  # custom regex

  # Simple security schemes (API key, HTTP bearer, etc.)
  settings.security_schemes = {
    "bearerAuth" => {"type" => "http", "scheme" => "bearer", "bearerFormat" => "JWT"},
    "apiKey"     => {"type" => "apiKey", "in" => "header", "name" => "X-API-Key"},
  }

  # OAuth2 security schemes with full flow definitions
  settings.oauth2_schemes = {
    "oauth2" => LuckySwagger::OAuth2Scheme.new(
      flows: {
        "authorizationCode" => LuckySwagger::OAuth2Flow.new(
          scopes:            {"read" => "Read access", "write" => "Write access"},
          authorization_url: "https://example.com/oauth/authorize",
          token_url:         "https://example.com/oauth/token"
        ),
      }
    ),
  }

  # Default security applied to all endpoints (override per-action with @[Endpoint(security:)])
  settings.default_security = [{"bearerAuth" => [] of String}]

  # Auth mixin → security scheme inference
  settings.auth_mixin_map = {
    "Api::Auth::RequireAuthToken" => "bearerAuth",
    "Api::Auth::RequireApiKey"    => "apiKey",
  }

  # Tag generation
  settings.tag_strip_prefixes = ["Api", "Actions", "V1", "V2"]
  settings.tag_separator      = " > "
  settings.default_tag        = "default"

  # Custom scalar type → OpenAPI format mapping (for parameter inference)
  settings.format_map = {
    "UUID"  => {type: "string", format: "uuid"},
    "Email" => {type: "string", format: "email"},
  }
end
```

---

## Tooling

### Generate the spec

```bash
# YAML (default)
lucky lucky_swagger.generate_open_api

# JSON
lucky lucky_swagger.generate_open_api --format json

# Custom output path
lucky lucky_swagger.generate_open_api -f ./public/openapi.yaml

# Validate after generating
lucky lucky_swagger.generate_open_api --validate
```

### Validate an existing spec

```bash
lucky lucky_swagger.generate_open_api --validate  # built-in structural check
lucky lucky_swagger.lint_spec --generate           # Spectral lint (requires Spectral)
```

Built-in validation checks: openapi version, info object, all `$ref` targets exist in `components/schemas`.

Install Spectral for full lint:

```bash
npm install -g @stoplight/spectral-cli
# or use npx — the task handles it automatically
```

### Programmatic API

```crystal
# YAML string
yaml = LuckySwagger::OpenApiGenerator.generate_yaml

# JSON string
json = LuckySwagger::OpenApiGenerator.generate_json

# Raw NamedTuple (for custom serialization)
spec = LuckySwagger::OpenApiGenerator.generate_open_api

# Validate a YAML string
errors = LuckySwagger::SpecValidator.validate(yaml)  # => Array(String)
LuckySwagger::SpecValidator.validate!(yaml)           # raises on error
```

### Scoped generation (testing / multi-tenant)

```crystal
LuckySwagger.temp_config(include_routes: /^\/api\/v2\//) do
  yaml = LuckySwagger::OpenApiGenerator.generate_yaml
end
```

---

## Live mode (development)

Serve the spec dynamically — no pre-generated file required:

```crystal
LuckySwagger::Handlers::WebHandler.new(swagger_url: "/api-docs", live: true)
```

The spec is regenerated on every request to `/api-docs/live.yaml`. Use this in development; use file-based serving in production.

---

## Demo application

See [demo/](demo/) for a working example with users, posts, and comments, covering pagination, enum params, security schemes, and request body schemas.

```bash
cd demo
podman run --rm -it --userns=keep-id -p 5000:5000 \
  -v "$PWD:/work:Z" -w /work docker.io/crystallang/crystal:latest \
  sh -c "shards install && crystal run src/demo.cr"
# substitute docker for podman, drop --userns=keep-id and :Z flags
```

Visit `http://localhost:5000/api-docs`

---

## Development

Container-first. Crystal runs inside the official `crystallang/crystal` image — no local Crystal install needed.

**Requirements:** `podman` or `docker`, `make`

```bash
make spec      # run test suite (185 examples)
make check     # verify formatting (CI)
make fmt       # format in-place
make shell     # interactive container shell
make help      # all targets
```

### Architecture

| Component | File | Role |
|-----------|------|------|
| Annotations | `src/lucky-swagger/annotations.cr` | Compile-time metadata markers |
| Documentable | `src/lucky-swagger/documentable.cr` | `swagger_fields` + `field` DSL |
| OpenApiGenerator | `src/lucky-swagger/generator/open_api_generator.cr` | Route + annotation → spec |
| SchemaIntrospector | `src/lucky-swagger/schema_introspector.cr` | Crystal type → OpenAPI schema |
| SpecValidator | `src/lucky-swagger/generator/validate_spec.cr` | Structural spec validation |
| WebHandler | `src/lucky-swagger/web/handlers/web_handler.cr` | SwaggerUI serving |
| Scenarios | `spec/fixtures/scenarios/` | Isolated regression fixtures |

---

## Contributing

1. Fork → feature branch → commit → PR
2. Each new inference rule or feature needs a scenario fixture in `spec/fixtures/scenarios/`
3. Run `make spec` and `make check` before pushing

## License

MIT

## Contributors

- [marmaxev](https://github.com/marmaxev) — creator and maintainer
