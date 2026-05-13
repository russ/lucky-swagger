require "../../spec_helper"

# Shared infrastructure for scenario fixtures.
#
# Each scenario lives in spec/fixtures/scenarios/<scenario_id>/ and contains:
#   - fixture .cr files defining actions, serializers, and operations
#   - a <scenario_id>_spec.cr file with assertions
#
# Scenarios are isolated by URL prefix: every action in a scenario uses a
# route under "/scenarios/<scenario_id>/...". The Scenarios.generate helper
# scopes the OpenAPI generation to that prefix so scenarios don't see each
# other's routes.

abstract class ScenarioAction < Lucky::Action
  accepted_formats [:json], default: :json
end

module Scenarios
  # Generate an OpenAPI spec scoped to a single scenario's URL prefix.
  # Returns the generator's NamedTuple result.
  def self.generate(scenario_id : String)
    filter = Regex.new("^/scenarios/#{Regex.escape(scenario_id)}/")
    spec = nil
    LuckySwagger.temp_config(include_routes: filter) do
      spec = LuckySwagger::OpenApiGenerator.generate_open_api
    end
    spec.not_nil!
  end
end
