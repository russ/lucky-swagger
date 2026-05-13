require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/for-collection-pagination/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

describe "S-04: for_collection_pagination" do
  it "wraps the inferred serializer in a paginated collection for Index actions" do
    yaml = generate_yaml
    schema = yaml["paths"]["/scenarios/for-collection-pagination/gadgets"]["get"]["responses"]["200"]["content"]["application/json"]["schema"]
    schema["type"].as_s.should eq("object")

    items = schema["properties"]["items"]
    items["type"].as_s.should eq("array")
    items["items"]["$ref"].as_s.should eq("#/components/schemas/Gadget")

    schema["properties"]["pagination"]["$ref"].as_s.should eq("#/components/schemas/Pagination")
  end

  it "registers the inferred serializer's schema in components" do
    schemas = generate_yaml["components"]["schemas"].as_h
    schemas.has_key?(YAML::Any.new("Gadget")).should be_true
  end

  it "always includes the built-in Pagination schema" do
    schemas = generate_yaml["components"]["schemas"].as_h
    schemas.has_key?(YAML::Any.new("Pagination")).should be_true
  end

  it "leaves Index actions with no matching serializer at the default response" do
    schema = generate_yaml["paths"]["/scenarios/for-collection-pagination/mysteries"]["get"]["responses"]["200"]["content"]["application/json"]["schema"]
    # Default response has type: object directly, no items/pagination wrapper
    schema.as_h.has_key?(YAML::Any.new("$ref")).should be_false
    schema.as_h.has_key?(YAML::Any.new("properties")).should be_false
  end
end
