require "lucky"
require "lucky-swagger"

# Require schemas and serializers first
require "./schemas/**"
require "./serializers/**"
require "./actions/**"
require "./errors/**"

# Generate the OpenAPI YAML
spec = LuckySwagger::OpenApiGenerator.generate_open_api

# Override the info section for the demo
output = {
  openapi:    spec[:openapi],
  info:       {
    title:       "Lucky Swagger Demo API",
    description: "Demonstration API showing lucky-swagger annotation features including typed schemas, request bodies, collection responses with pagination, and enum-constrained parameters.",
    version:     "2.0.0",
  },
  paths:      spec[:paths],
  components: spec[:components],
}

File.open("./swagger/api.yaml", "w") do |file|
  YAML.dump(output, file)
end

puts "✅ Generated swagger/api.yaml"
