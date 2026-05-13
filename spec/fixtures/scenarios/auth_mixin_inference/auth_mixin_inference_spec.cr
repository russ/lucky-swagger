require "yaml"
require "../scenarios_helper"
require "./fixtures"

# Generate the spec scoped to this scenario, with the auth_mixin_map configured,
# and parse back through YAML so we can introspect the dynamic structure.
private def generate_yaml
  filter = Regex.new("^/scenarios/auth-mixin-inference/")
  mixin_map = {
    "AuthMixinInferenceScenario::FakeAuth::RequireBearer" => "bearerAuth",
    "AuthMixinInferenceScenario::FakeAuth::RequireApiKey" => "apiKeyAuth",
  }
  spec = nil
  LuckySwagger.temp_config(include_routes: filter, auth_mixin_map: mixin_map) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def operation_for(path : String)
  generate_yaml["paths"][path]["get"]
end

describe "S-01: auth_mixin_inference" do
  it "infers the mapped scheme when an action includes a registered mixin" do
    op = operation_for("/scenarios/auth-mixin-inference/bearer-only")
    op["security"].as_a.should eq([{"bearerAuth" => [] of String}])
  end

  it "emits no security key when the action has no registered mixins and no default" do
    op = operation_for("/scenarios/auth-mixin-inference/public").as_h
    op.has_key?(YAML::Any.new("security")).should be_false
  end

  it "lets @[Endpoint(security: \"none\")] override the inferred mixin" do
    op = operation_for("/scenarios/auth-mixin-inference/override-none")
    op["security"].as_a.should eq([] of YAML::Any)
  end

  it "AND-combines multiple matched mixins into a single requirement" do
    op = operation_for("/scenarios/auth-mixin-inference/both")
    security = op["security"].as_a
    security.size.should eq(1)
    security.first.as_h.keys.map(&.as_s).sort.should eq(["apiKeyAuth", "bearerAuth"])
  end
end
