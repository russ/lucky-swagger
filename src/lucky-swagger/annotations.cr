# Annotations for marking schemas and documenting API endpoints.
# Place these annotations on Action CLASSES, not on macro calls (like `post`, `get`, etc.)

module LuckySwagger
  # Marks a struct/class as an API schema for introspection.
  annotation Schema
  end

  # Defines the request body schema for an action class.
  # Usage:
  #   @[LuckySwagger::RequestBody(schema: UserCreateRequest)]
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

  # Defines endpoint metadata (summary, description, tags).
  # Usage:
  #   @[LuckySwagger::Endpoint(summary: "List users", description: "...", tags: ["Users"])]
  annotation Endpoint
  end
end
