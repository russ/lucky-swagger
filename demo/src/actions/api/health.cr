class Api::Health < ApiAction
  # Simple health check endpoint
  get "/api/health" do
    json({
      status: "healthy",
      timestamp: Time.utc.to_s
    })
  end
end
