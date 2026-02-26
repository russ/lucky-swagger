@[LuckySwagger::Endpoint(summary: "Health check", description: "Returns the current API health status and server timestamp", tags: ["System"])]
@[LuckySwagger::Response(200, description: "API is healthy")]
class Api::Health < ApiAction
  get "/api/health" do
    json({
      status:    "healthy",
      timestamp: Time.utc.to_s,
      version:   "1.0.0",
    })
  end
end
