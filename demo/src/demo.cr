require "lucky"
require "lucky-swagger"

# Require schemas and serializers first
require "./schemas/**"
require "./serializers/**"

# Require all application files
require "./actions/**"
require "./app_server"
require "./errors/**"

# Configure LuckySwagger
LuckySwagger.configure do |settings|
  settings.title = "Lucky Demo API"
  settings.description = "A comprehensive demo showcasing Lucky framework API with OpenAPI documentation"
  settings.version = "2.0.0"

  # Configure servers for different environments
  settings.servers = [
    {url: "http://localhost:5000", description: "Development server"},
    {url: "https://api.example.com", description: "Production server"},
  ]

  # Default to including all routes (not just api routes)
  settings.include_routes = :all

  # Configure security schemes for authentication
  settings.security_schemes = {
    "bearerAuth" => {
      "type" => "http",
      "scheme" => "bearer",
      "bearerFormat" => "JWT",
    },
    "apiKey" => {
      "type" => "apiKey",
      "in" => "header",
      "name" => "X-API-Key",
    },
  }

  # Apply bearer auth by default to all endpoints
  settings.default_security = [
    {"bearerAuth" => [] of String},
  ]
end

# Configure Lucky
Lucky::Server.configure do |settings|
  settings.secret_key_base = "demo_secret_key_base_change_in_production"
  settings.host = "0.0.0.0"
  settings.port = 5000
end

# Start the server
puts "Starting demo server on http://localhost:5000"
puts "SwaggerUI available at http://localhost:5000/api-docs"
puts ""

AppServer.new.listen
