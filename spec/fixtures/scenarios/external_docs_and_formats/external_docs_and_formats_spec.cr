require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/external-docs-and-formats/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def operation(path : String, method : String = "get")
  generate_yaml["paths"][path][method]
end

private def schemas
  generate_yaml["components"]["schemas"].as_h
end

describe "S-17: external_docs_and_formats" do
  describe "EF-9: externalDocs on operations" do
    it "emits externalDocs with url and description" do
      op = operation("/scenarios/external-docs-and-formats/assets/{id}")
      op.as_h.has_key?(YAML::Any.new("externalDocs")).should be_true
      op["externalDocs"]["url"].as_s.should eq("https://docs.example.com/assets")
      op["externalDocs"]["description"].as_s.should eq("Asset API docs")
    end

    it "emits externalDocs with url only when description is absent" do
      op = operation("/scenarios/external-docs-and-formats/simple")
      op.as_h.has_key?(YAML::Any.new("externalDocs")).should be_true
      op["externalDocs"]["url"].as_s.should eq("https://docs.example.com/simple")
      op["externalDocs"].as_h.has_key?(YAML::Any.new("description")).should be_false
    end

    it "does not emit externalDocs when annotation is absent" do
      op = operation("/scenarios/external-docs-and-formats/no-docs")
      op.as_h.has_key?(YAML::Any.new("externalDocs")).should be_false
    end
  end

  describe "EF-10: ScalarFormat annotation on custom types" do
    it "emits type: string and format: uuid for ScalarFormat-annotated type" do
      asset_schema = schemas[YAML::Any.new("Asset")]
      id_prop = asset_schema["properties"]["id"].as_h
      id_prop[YAML::Any.new("type")].as_s.should eq("string")
      id_prop[YAML::Any.new("format")].as_s.should eq("uuid")
    end

    it "emits nullable: true with correct type for optional ScalarFormat field" do
      asset_schema = schemas[YAML::Any.new("Asset")]
      ref_prop = asset_schema["properties"]["optional_ref"].as_h
      ref_prop[YAML::Any.new("type")].as_s.should eq("string")
      ref_prop[YAML::Any.new("format")].as_s.should eq("uuid")
      ref_prop[YAML::Any.new("nullable")].as_bool.should be_true
    end

    it "still emits example from FieldMeta on a ScalarFormat field" do
      asset_schema = schemas[YAML::Any.new("Asset")]
      id_prop = asset_schema["properties"]["id"].as_h
      id_prop[YAML::Any.new("example")].as_s.should eq("550e8400-e29b-41d4-a716-446655440000")
    end
  end
end
