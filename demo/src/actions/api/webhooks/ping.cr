@[LuckySwagger::Endpoint(
  summary: "Health check ping",
  description: "Returns 'pong'. Used by uptime monitors and load balancers. No authentication required.",
  security: "none",
)]
@[LuckySwagger::Response(200, content_type: "text/plain", description: "Pong response", example: "pong")]
class Api::Webhooks::Ping < ApiAction
  get "/api/webhooks/ping" do
    plain_text "ok"
  end
end
