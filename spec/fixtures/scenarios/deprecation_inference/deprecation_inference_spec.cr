require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/deprecation-inference/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def operation_for(path : String)
  generate_yaml["paths"][path]["get"].as_h
end

describe "S-07: deprecation_inference" do
  it "marks deprecated: true when @[LuckySwagger::Endpoint(deprecated: true)] is set" do
    op = operation_for("/scenarios/deprecation-inference/deprecated")
    op[YAML::Any.new("deprecated")].as_bool.should be_true
  end

  it "omits the deprecated key for active actions" do
    op = operation_for("/scenarios/deprecation-inference/active")
    op.has_key?(YAML::Any.new("deprecated")).should be_false
  end
end
