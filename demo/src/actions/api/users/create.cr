@[LuckySwagger::Endpoint(summary: "Create user", description: "Creates a new user account. Email and username must be unique.", tags: ["Users"])]
@[LuckySwagger::RequestBody(schema: UserCreateRequest)]
@[LuckySwagger::Response(201, serializer: UserSerializer, description: "User created successfully")]
@[LuckySwagger::Response(422, schema: LuckySwagger::ErrorSchema, description: "Validation failed (e.g. duplicate email, missing required fields)")]
class Api::Users::Create < ApiAction
  post "/api/users" do
    json({
      message: "Create a new user",
      status:  "created",
    })
  end
end
