require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/multipart-required/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def multipart_schema(path : String, method : String)
  generate_yaml["paths"][path][method]["requestBody"]["content"]["multipart/form-data"]["schema"]
end

describe "S-32: multipart_required" do
  describe "single required field" do
    it "emits required array with the declared field" do
      schema = multipart_schema("/scenarios/multipart-required/profile", "put")
      schema["required"].as_a.map(&.as_s).should eq(["avatar"])
    end

    it "non-required fields are absent from required array" do
      schema = multipart_schema("/scenarios/multipart-required/profile", "put")
      schema["required"].as_a.map(&.as_s).should_not contain("bio")
      schema["required"].as_a.map(&.as_s).should_not contain("website")
    end
  end

  describe "multiple required fields" do
    it "emits required array with all declared fields" do
      schema = multipart_schema("/scenarios/multipart-required/documents", "post")
      required = schema["required"].as_a.map(&.as_s)
      required.should contain("document")
      required.should contain("title")
    end

    it "non-required field is absent from required array" do
      schema = multipart_schema("/scenarios/multipart-required/documents", "post")
      schema["required"].as_a.map(&.as_s).should_not contain("summary")
    end
  end

  describe "no required key when not declared" do
    it "required key is absent when required: is omitted" do
      schema = multipart_schema("/scenarios/multipart-required/notes", "post")
      schema.as_h.has_key?(YAML::Any.new("required")).should be_false
    end

    it "all fields still appear in properties" do
      schema = multipart_schema("/scenarios/multipart-required/notes", "post")
      props = schema["properties"].as_h
      props.has_key?(YAML::Any.new("name")).should be_true
      props.has_key?(YAML::Any.new("note")).should be_true
    end
  end
end
