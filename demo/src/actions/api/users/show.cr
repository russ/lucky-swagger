@[LuckySwagger::Endpoint(summary: "Get user", description: "Returns detailed information for a specific user", tags: ["Users"])]
@[LuckySwagger::Response(200, serializer: UserSerializer, description: "User details")]
@[LuckySwagger::Response(404, schema: LuckySwagger::ErrorSchema, description: "User not found")]
class Api::Users::Show < ApiAction
  get "/api/users/:user_id" do
    json({
      message: "Show user details",
      user_id: user_id,
    })
  end
end
