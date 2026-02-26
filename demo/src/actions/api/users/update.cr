@[LuckySwagger::Endpoint(summary: "Update user", description: "Updates an existing user. Only provided fields are changed.", tags: ["Users"])]
@[LuckySwagger::RequestBody(schema: UserUpdateRequest)]
@[LuckySwagger::Response(200, serializer: UserSerializer, description: "User updated successfully")]
@[LuckySwagger::Response(404, schema: LuckySwagger::ErrorSchema, description: "User not found")]
@[LuckySwagger::Response(422, schema: LuckySwagger::ErrorSchema, description: "Validation failed")]
class Api::Users::Update < ApiAction
  put "/api/users/:user_id" do
    json({
      message: "Update user",
      user_id: user_id,
    })
  end
end
