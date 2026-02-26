# lucky-swagger

[![CI](https://github.com/marmaxev/lucky-swagger/actions/workflows/ci.yml/badge.svg)](https://github.com/marmaxev/lucky-swagger/actions/workflows/ci.yml)

Automatic OpenAPI 3.0 documentation generation for Lucky framework applications with integrated SwaggerUI.

Generate type-safe API specs from your Lucky actions and serializers using annotations. No manual YAML editing required.

## Installation

Add to your `shard.yml`:

```yaml
dependencies:
  lucky-swagger:
    github: marmaxev/lucky-swagger
```

Run `shards install` and require the shard:

```crystal
require "lucky-swagger"
```

## Quick Start

### 1. Enable SwaggerUI

Add the web handler to `src/app_server.cr`:

```crystal
class AppServer < Lucky::BaseAppServer
  def middleware : Array(HTTP::Handler)
    [
      Lucky::LogHandler.new,
      LuckySwagger::Handlers::WebHandler.new(
        swagger_url: "/api-docs",  # SwaggerUI will be available here
        folder: "./swagger"         # Path to generated YAML files
      ),
      Lucky::ErrorHandler.new(action: Errors::Show),
      Lucky::RouteHandler.new,
    ] of HTTP::Handler
  end
end
```

### 2. Configure LuckySwagger

In your application setup (e.g., `src/app.cr`):

```crystal
LuckySwagger.configure do |settings|
  settings.title = "My API"
  settings.description = "API documentation"
  settings.version = "1.0.0"
end
```

### 3. Generate OpenAPI spec

```bash
crystal run src/generate_yaml.cr
```

Visit `http://localhost:5000/api-docs` to see your interactive API documentation.

## Configuration

Full configuration options:

```crystal
LuckySwagger.configure do |settings|
  # API metadata
  settings.title = "My API"
  settings.description = "Comprehensive API documentation"
  settings.version = "2.0.0"

  # Server environments
  settings.servers = [
    {url: "http://localhost:5000", description: "Development"},
    {url: "https://api.example.com", description: "Production"},
  ]

  # Route filtering
  settings.include_routes = :all           # Include all routes (default)
  # settings.include_routes = :api_only    # Only routes with "api" in path
  # settings.include_routes = /^\/api\//   # Custom regex filter

  # Security schemes (authentication methods)
  settings.security_schemes = {
    "bearerAuth" => {
      "type"         => "http",
      "scheme"       => "bearer",
      "bearerFormat" => "JWT",
    },
    "apiKey" => {
      "type" => "apiKey",
      "in"   => "header",
      "name" => "X-API-Key",
    },
  }

  # Default security applied to all endpoints (can be overridden per-action)
  settings.default_security = [
    {"bearerAuth" => [] of String},
  ]
end
```

## Annotations

### @[LuckySwagger::Endpoint]

Document action metadata. Place on action classes:

```crystal
@[LuckySwagger::Endpoint(
  summary: "List users",
  description: "Returns paginated list of users with filtering",
  tags: ["Users"],
  security: "bearerAuth",  # Override default security
  deprecated: false
)]
class Api::Users::Index < ApiAction
  get "/api/users" do
    # ...
  end
end
```

**Security options:**
- `security: "bearerAuth"` - Use specific scheme
- `security: "none"` - Public endpoint, no authentication required
- Omit to use `default_security` from configuration

### @[LuckySwagger::Response]

Define response schemas by status code (use multiple times for different status codes):

```crystal
# Single object response
@[LuckySwagger::Response(200, serializer: UserSerializer, description: "User found")]

# Collection response
@[LuckySwagger::Response(200, serializer: UserSerializer, collection: true, description: "List of users")]

# Direct schema (for JSON::Serializable structs)
@[LuckySwagger::Response(201, schema: UserCreateResponse)]

# Error responses
@[LuckySwagger::Response(404, schema: LuckySwagger::ErrorSchema, description: "User not found")]
@[LuckySwagger::Response(422, schema: LuckySwagger::ErrorSchema, description: "Validation failed")]

class Api::Users::Show < ApiAction
  get "/api/users/:id" do
    # ...
  end
end
```

**Collection responses** automatically include pagination metadata in the generated schema.

### @[LuckySwagger::RequestBody]

Specify request body schema:

```crystal
@[LuckySwagger::RequestBody(schema: UserCreateRequest)]
class Api::Users::Create < ApiAction
  post "/api/users" do
    # ...
  end
end
```

Schema must be a `JSON::Serializable` struct:

```crystal
struct UserCreateRequest
  include JSON::Serializable

  property email : String
  property password : String
  property name : String
  property bio : String?
end
```

## Serializer Schemas

Define typed response schemas with `swagger_fields`:

```crystal
struct UserSerializer < BaseSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    property id : Int64
    property email : String
    property name : String
    property bio : String?
    property active : Bool
    property created_at : Time
  end
end
```

The generator introspects `swagger_fields` at compile-time to build OpenAPI schemas with proper types and required/optional fields.

## Enum Constraints

Constrain query parameters to specific values:

```crystal
class Api::Posts::Index < ApiAction
  include LuckySwagger::Documentable

  param sort_by : String = "created_at"
  swagger_enum sort_by, ["created_at", "title", "author", "views"]

  get "/api/posts" do
    # ...
  end
end
```

The OpenAPI spec will include:

```yaml
parameters:
  - name: sort_by
    in: query
    schema:
      type: string
      enum: [created_at, title, author, views]
```

## Built-in Schemas

LuckySwagger provides reusable schemas:

### Pagination

```crystal
@[LuckySwagger::Response(200, serializer: PostSerializer, collection: true)]
```

Generates a response with:

```json
{
  "data": [...],
  "pagination": {
    "next_page": "...",
    "previous_page": "...",
    "total_items": 100,
    "total_pages": 10,
    "per_page": 25
  }
}
```

### Error

```crystal
@[LuckySwagger::Response(422, schema: LuckySwagger::ErrorSchema)]
```

Generates:

```json
{
  "message": "Validation failed",
  "param": "email",
  "details": "Email must be unique"
}
```

## SchemaIntrospector

For advanced use cases, manually generate schemas from any `JSON::Serializable` type:

```crystal
# Generate OpenAPI schema hash
schema = LuckySwagger::SchemaIntrospector.openapi_schema(MyStruct)

# Generate TypeScript interface
typescript = LuckySwagger::SchemaIntrospector.typescript_interface(MyStruct)
```

## YAML Generation

### Standalone script

Create `src/generate_yaml.cr`:

```crystal
require "lucky"
require "lucky-swagger"

# Require schemas, serializers, and actions
require "./schemas/**"
require "./serializers/**"
require "./actions/**"

# Configuration (same as your app)
LuckySwagger.configure do |settings|
  settings.title = "My API"
  settings.version = "1.0.0"
  # ... other settings
end

# Generate spec
spec = LuckySwagger::OpenApiGenerator.generate_open_api

# Write to file
File.open("./swagger/api.yaml", "w") do |file|
  YAML.dump(spec, file)
end

puts "✅ Generated swagger/api.yaml"
```

Run:

```bash
crystal run src/generate_yaml.cr
```

### Lucky Task

Create `tasks/generate_swagger.cr`:

```crystal
require "lucky_task"

class GenerateSwagger < LuckyTask::Task
  summary "Generate OpenAPI documentation"

  def call
    generator = LuckySwagger::GenerateOpenApi.new
    generator.call
  end
end
```

Run:

```bash
lucky generate_swagger
```

## Complete Example

```crystal
# Serializer
struct UserSerializer < BaseSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    property id : Int64
    property email : String
    property name : String
    property role : String
    property active : Bool
    property created_at : Time
  end
end

# Request schema
struct UserCreateRequest
  include JSON::Serializable

  property email : String
  property name : String
  property role : String
end

# Action
@[LuckySwagger::Endpoint(
  summary: "Create user",
  description: "Creates a new user account with the provided details",
  tags: ["Users"]
)]
@[LuckySwagger::RequestBody(schema: UserCreateRequest)]
@[LuckySwagger::Response(201, serializer: UserSerializer, description: "User created")]
@[LuckySwagger::Response(422, schema: LuckySwagger::ErrorSchema, description: "Validation failed")]
class Api::Users::Create < ApiAction
  post "/api/users" do
    # Implementation
  end
end
```

## Demo Application

See the [demo app](demo/) for a full working example with:
- Multiple endpoints with various response types
- Pagination
- Enum-constrained parameters
- Security schemes
- Request body validation
- Error responses

Run the demo:

```bash
cd demo
shards install
crystal run src/demo.cr
```

Visit `http://localhost:5000/api-docs`

## Development

### Running Specs

Tests run in a Podman container for consistent environments:

```bash
# Run all specs
bin/test

# Run specific spec file
bin/test spec/lucky-swagger_spec.cr

# Force rebuild container
bin/test --build
```

### Architecture

- **Annotations**: Compile-time metadata for actions and responses
- **OpenApiGenerator**: Introspects Lucky routes and annotations to build OpenAPI spec
- **SchemaIntrospector**: Converts Crystal types to OpenAPI schemas
- **WebHandler**: Serves SwaggerUI with your generated YAML

## Contributing

1. Fork it (<https://github.com/marmaxev/lucky-swagger/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

MIT

## Contributors

- [marmaxev](https://github.com/marmaxev) - creator and maintainer
