require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/examples/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def media_type(path : String, status : String = "200", method : String = "get")
  generate_yaml["paths"][path][method]["responses"][status]["content"]
end

private def article_schema
  generate_yaml["components"]["schemas"]["Article"]
end

describe "S-14: examples" do
  describe "field-level examples via FieldMeta" do
    it "emits example on an Int64 field" do
      article_schema["properties"]["id"]["example"].as_i.should eq(42)
    end

    it "emits example on a String field" do
      article_schema["properties"]["title"]["example"].as_s.should eq("Hello World")
    end

    it "emits example on a nullable String field" do
      article_schema["properties"]["status"]["example"].as_s.should eq("draft")
    end

    it "does not emit example on fields without FieldMeta" do
      article_schema["properties"]["view_count"].as_h.has_key?(YAML::Any.new("example")).should be_false
    end
  end

  describe "response-level examples via serializer" do
    it "emits example on the application/json media type object" do
      mt = media_type("/scenarios/examples/articles/{id}")
      mt["application/json"].as_h.has_key?(YAML::Any.new("example")).should be_true
    end

    it "emits the example value correctly" do
      mt = media_type("/scenarios/examples/articles/{id}")
      example = mt["application/json"]["example"].as_h
      example[YAML::Any.new("id")].as_i.should eq(42)
      example[YAML::Any.new("title")].as_s.should eq("Hello World")
    end
  end

  describe "response-level examples via schema ref" do
    it "emits example on the application/json media type object" do
      mt = media_type("/scenarios/examples/articles/{id}/alt")
      mt["application/json"].as_h.has_key?(YAML::Any.new("example")).should be_true
    end
  end

  describe "response-level examples on non-JSON responses" do
    it "emits example on the text/plain media type object" do
      mt = media_type("/scenarios/examples/ping")
      mt["text/plain"].as_h.has_key?(YAML::Any.new("example")).should be_true
    end

    it "emits the string example value" do
      mt = media_type("/scenarios/examples/ping")
      mt["text/plain"]["example"].as_s.should eq("pong")
    end
  end

  describe "response without example" do
    it "does not emit example key when annotation has none" do
      mt = media_type("/scenarios/examples/articles/{id}/no-example")
      mt["application/json"].as_h.has_key?(YAML::Any.new("example")).should be_false
    end
  end
end
