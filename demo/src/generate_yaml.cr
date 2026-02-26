require "lucky"
require "lucky-swagger"

# Require schemas and serializers first
require "./schemas/**"
require "./serializers/**"
require "./actions/**"
require "./errors/**"

# Configure LuckySwagger (same as demo.cr)
LuckySwagger.configure do |settings|
  settings.title = "Lucky Swagger Demo API"
  settings.description = "Demonstration API showing lucky-swagger annotation features including typed schemas, request bodies, collection responses with pagination, and enum-constrained parameters."
  settings.version = "2.0.0"

  settings.servers = [
    {url: "http://localhost:5000", description: "Development server"},
    {url: "https://api.example.com", description: "Production server"},
  ]

  settings.include_routes = :all

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

  settings.default_security = [
    {"bearerAuth" => [] of String},
  ]
end

# Generate the full OpenAPI spec from config + annotations
spec = LuckySwagger::OpenApiGenerator.generate_open_api

File.open("./swagger/api.yaml", "w") do |file|
  YAML.dump(spec, file)
end

puts "✅ Generated swagger/api.yaml"
