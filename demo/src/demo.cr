require "lucky"
require "lucky-swagger"

# Require schemas and serializers — base must load before subclasses
require "./schemas/**"
require "./serializers/base_serializer"
require "./serializers/**"

# Require all application files
require "./actions/**"
require "./app_server"
require "./errors/**"

# Configure LuckySwagger
LuckySwagger.configure do |settings|
  settings.title       = "Lucky Demo API"
  settings.description = "Full demo of lucky-swagger features: inference, polymorphic responses, " \
                         "file upload, non-JSON responses, OAuth2, field constraints, and more."
  settings.version     = "2.0.0"

  settings.contact = {name: "Demo Team", email: "demo@example.com", url: nil}
  settings.license = {name: "MIT", url: "https://opensource.org/licenses/MIT"}

  settings.servers = [
    {url: "http://localhost:5000", description: "Local development"},
    {url: "https://api.example.com", description: "Production"},
  ]

  settings.include_routes = :all

  # Simple HTTP/API key schemes
  settings.security_schemes = {
    "bearerAuth" => {
      "type"         => "http",
      "scheme"       => "bearer",
      "bearerFormat" => "JWT",
    },
    "apiKey" => {
      "type" => "apiKey",
      "in"   => "header",
      "name" => "X-API-Key",
    },
  }

  # OAuth2 with authorizationCode and clientCredentials flows
  settings.oauth2_schemes = {
    "oauth2" => LuckySwagger::OAuth2Scheme.new(
      flows: {
        "authorizationCode" => LuckySwagger::OAuth2Flow.new(
          scopes:            {
            "read:streams"    => "Read stream data",
            "write:streams"   => "Create and update streams",
            "read:analytics"  => "Access analytics data",
            "manage:users"    => "Manage user accounts",
          },
          authorization_url: "https://example.com/oauth/authorize",
          token_url:         "https://example.com/oauth/token"
        ),
        "clientCredentials" => LuckySwagger::OAuth2Flow.new(
          scopes:    {
            "read:streams"   => "Read stream data",
            "read:analytics" => "Access analytics data",
          },
          token_url: "https://example.com/oauth/token"
        ),
      }
    ),
  }

  # Bearer auth on all endpoints by default (override with security: "none" per action)
  settings.default_security = [{"bearerAuth" => [] of String}]

  # Strip only the top-level "Api" prefix so inner namespaces become tag groups:
  # Api::Frontend::Streams → "Frontend > Streams"
  # Api::Office::Analytics → "Office > Analytics"
  # Api::Users → "Users"
  settings.tag_strip_prefixes = ["Api"]
  settings.tag_separator      = " > "
end

# Configure Lucky
Lucky::Server.configure do |settings|
  settings.secret_key_base = "demo_secret_key_base_change_in_production"
  settings.host = "0.0.0.0"
  settings.port = 5000
end

# Start the server
puts "Starting demo server"
puts "  Local:   http://localhost:5000/api-docs"
puts "  Network: http://192.168.7.204:5000/api-docs"
puts ""

AppServer.new.listen
