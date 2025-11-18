require "lucky"
require "lucky-swagger"

# Require all actions so routes are registered
require "../src/actions/**"

# This task generates the OpenAPI YAML file
class GenerateSwagger < LuckyTask::Task
  summary "Generate OpenAPI documentation for the demo API"

  def call
    # Use the LuckySwagger generator
    generator = LuckySwagger::GenerateOpenApi.new
    generator.call
  end
end
