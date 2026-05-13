require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/polymorphic-response/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def response_schema(method : String, path : String, status : String = "200")
  generate_yaml["paths"][path][method]["responses"][status]["content"]["application/json"]["schema"].as_h
end

private def schemas
  generate_yaml["components"]["schemas"].as_h
end

describe "S-09: polymorphic_response" do
  describe "oneOf" do
    it "emits oneOf key in the response schema" do
      schema = response_schema("get", "/scenarios/polymorphic-response/poly-pets/{id}")
      schema.has_key?(YAML::Any.new("oneOf")).should be_true
    end

    it "emits $ref entries for each type in the oneOf array" do
      schema = response_schema("get", "/scenarios/polymorphic-response/poly-pets/{id}")
      refs = schema[YAML::Any.new("oneOf")].as_a.map { |r| r["$ref"].as_s }
      refs.should contain("#/components/schemas/PetCatResponse")
      refs.should contain("#/components/schemas/PetDogResponse")
    end

    it "registers each oneOf type in components/schemas" do
      s = schemas
      s.has_key?(YAML::Any.new("PetCatResponse")).should be_true
      s.has_key?(YAML::Any.new("PetDogResponse")).should be_true
    end

    it "does NOT emit anyOf or allOf keys when oneOf is declared" do
      schema = response_schema("get", "/scenarios/polymorphic-response/poly-pets/{id}")
      schema.has_key?(YAML::Any.new("anyOf")).should be_false
      schema.has_key?(YAML::Any.new("allOf")).should be_false
    end
  end

  describe "anyOf" do
    it "emits anyOf key in the response schema" do
      schema = response_schema("get", "/scenarios/polymorphic-response/any-pets/{id}")
      schema.has_key?(YAML::Any.new("anyOf")).should be_true
    end

    it "emits $ref entries for each type in the anyOf array" do
      schema = response_schema("get", "/scenarios/polymorphic-response/any-pets/{id}")
      refs = schema[YAML::Any.new("anyOf")].as_a.map { |r| r["$ref"].as_s }
      refs.should contain("#/components/schemas/PetCatResponse")
      refs.should contain("#/components/schemas/PetDogResponse")
    end
  end

  describe "allOf" do
    it "emits allOf key in the response schema" do
      schema = response_schema("get", "/scenarios/polymorphic-response/composed-pets/{id}")
      schema.has_key?(YAML::Any.new("allOf")).should be_true
    end

    it "emits $ref entries for each type in the allOf array" do
      schema = response_schema("get", "/scenarios/polymorphic-response/composed-pets/{id}")
      refs = schema[YAML::Any.new("allOf")].as_a.map { |r| r["$ref"].as_s }
      refs.should contain("#/components/schemas/PetBaseResponse")
      refs.should contain("#/components/schemas/PetExtensionResponse")
    end

    it "registers allOf types in components/schemas" do
      s = schemas
      s.has_key?(YAML::Any.new("PetBaseResponse")).should be_true
      s.has_key?(YAML::Any.new("PetExtensionResponse")).should be_true
    end
  end
end
