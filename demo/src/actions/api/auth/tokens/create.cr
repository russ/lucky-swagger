@[LuckySwagger::Endpoint(
  summary: "Create auth token",
  description: "Exchange credentials for an access or refresh token. The response shape depends on grant_type — use the discriminator to distinguish them.",
  security: "none",
)]
@[LuckySwagger::RequestBody(schema: TokenRequest)]
@[LuckySwagger::Response(200, one_of: [AccessTokenShape, RefreshTokenShape], discriminator: "grant_type", description: "Token issued")]
@[LuckySwagger::Response(401, schema: LuckySwagger::ErrorSchema, description: "Invalid credentials or expired refresh token")]
@[LuckySwagger::Response(422, schema: LuckySwagger::ErrorSchema, description: "Missing or invalid grant_type")]
class Api::Auth::Tokens::Create < ApiAction
  post "/api/auth/token" do
    plain_text "ok"
  end
end
