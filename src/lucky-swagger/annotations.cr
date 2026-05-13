# Annotations for marking schemas and documenting API endpoints.
# Place these annotations on Action CLASSES, not on macro calls (like `post`, `get`, etc.)

module LuckySwagger
  # Marks a struct/class as an API schema for introspection.
  annotation Schema
  end

  # Defines the request body schema for an action class.
  # Usage:
  #   @[LuckySwagger::RequestBody(schema: UserCreateRequest)]
  #   @[LuckySwagger::RequestBody(multipart: {avatar: File, bio: String})]
  #   @[LuckySwagger::RequestBody(multipart: {avatar: File, bio: String}, required: [:avatar])]
  annotation RequestBody
  end

  # Defines response schemas by status code (can be used multiple times).
  # Supports serializer-based schemas (with optional collection wrapping)
  # and direct JSON::Serializable schemas.
  #
  # Usage:
  #   @[LuckySwagger::Response(200, serializer: UserSerializer)]
  #   @[LuckySwagger::Response(200, serializer: PostSerializer, collection: true)]
  #   @[LuckySwagger::Response(200, schema: SomeJsonSerializable)]
  #   @[LuckySwagger::Response(422, schema: LuckySwagger::ErrorSchema, description: "Validation failed")]
  annotation Response
  end

  # Defines endpoint metadata (summary, description, tags, security, deprecated, operation_id).
  # Usage:
  #   @[LuckySwagger::Endpoint(summary: "List users", description: "...", tags: ["Users"])]
  #   @[LuckySwagger::Endpoint(security: "bearerAuth")]
  #   @[LuckySwagger::Endpoint(security: "none")]  # Public endpoint, no auth required
  #   @[LuckySwagger::Endpoint(deprecated: true)]
  #   @[LuckySwagger::Endpoint(operation_id: "listUsers")]
  annotation Endpoint
  end

  # Declares a header parameter for an action. Can be stacked for multiple headers.
  #
  # Usage:
  #   @[LuckySwagger::HeaderParam(name: "X-Request-ID", type: String, required: false, description: "Trace ID")]
  #   @[LuckySwagger::HeaderParam(name: "Authorization", type: String, required: true)]
  annotation HeaderParam
  end

  # Marks a custom scalar type with its OpenAPI type/format mapping.
  # Apply to user-defined scalar types so SchemaIntrospector emits the
  # correct type and format instead of falling back to {type: "object"}.
  #
  # Usage:
  #   @[LuckySwagger::ScalarFormat(type: "string", format: "uuid")]
  #   struct UUID
  #     ...
  #   end
  annotation ScalarFormat
  end

  # Attaches example metadata to a swagger_fields property.
  # The generator reads this at compile time and emits `example:` in the schema property.
  #
  # Usage (inside swagger_fields block):
  #   @[LuckySwagger::FieldMeta(example: "Alice")]
  #   property name : String
  annotation FieldMeta
  end

  # Declares a cookie parameter for an action. Can be stacked for multiple cookies.
  #
  # Usage:
  #   @[LuckySwagger::CookieParam(name: "session_id", type: String, required: false, description: "Session token")]
  annotation CookieParam
  end

  # Binds an action to the operation that handles its request body. The
  # referenced operation must include LuckySwagger::Documentable and use
  # `swagger_fields { }` to declare its schema.
  #
  # Convention: actions named `<Resource>::Create` or `<Resource>::Update`
  # automatically look for a top-level `Save<Resource>` operation. Use this
  # annotation for non-conventional naming or to override the convention.
  #
  # Usage:
  #   @[LuckySwagger::Operation(SaveUser)]
  annotation Operation
  end
end
