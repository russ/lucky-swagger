require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/discriminator/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def schema_for(path : String, method : String = "get")
  generate_yaml["paths"][path][method]["responses"]["200"]["content"]["application/json"]["schema"].as_h
end

describe "S-15: discriminator" do
  describe "oneOf with discriminator" do
    it "emits discriminator object with propertyName" do
      schema = schema_for("/scenarios/discriminator/events/{id}")
      schema.has_key?(YAML::Any.new("discriminator")).should be_true
      schema[YAML::Any.new("discriminator")]["propertyName"].as_s.should eq("kind")
    end

    it "still emits the oneOf refs alongside discriminator" do
      schema = schema_for("/scenarios/discriminator/events/{id}")
      refs = schema[YAML::Any.new("oneOf")].as_a.map { |r| r["$ref"].as_s }
      refs.should contain("#/components/schemas/EventCreated")
      refs.should contain("#/components/schemas/EventDeleted")
    end
  end

  describe "anyOf with discriminator" do
    it "emits discriminator object with propertyName on anyOf" do
      schema = schema_for("/scenarios/discriminator/events/{id}/any")
      schema.has_key?(YAML::Any.new("discriminator")).should be_true
      schema[YAML::Any.new("discriminator")]["propertyName"].as_s.should eq("kind")
    end

    it "still emits the anyOf refs" do
      schema = schema_for("/scenarios/discriminator/events/{id}/any")
      schema.has_key?(YAML::Any.new("anyOf")).should be_true
    end
  end

  describe "allOf without discriminator" do
    it "does not emit discriminator when not specified" do
      schema = schema_for("/scenarios/discriminator/events/{id}/all")
      schema.has_key?(YAML::Any.new("discriminator")).should be_false
    end
  end
end
