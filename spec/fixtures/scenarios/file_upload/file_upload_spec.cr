require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/file-upload/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def request_body(path : String)
  generate_yaml["paths"][path]["post"]["requestBody"]
end

private def properties(path : String)
  request_body(path)["content"]["multipart/form-data"]["schema"]["properties"].as_h
end

describe "S-12: file_upload" do
  describe "content type" do
    it "emits multipart/form-data content type" do
      rb = request_body("/scenarios/file-upload/avatar")
      rb["content"].as_h.has_key?(YAML::Any.new("multipart/form-data")).should be_true
    end

    it "does not emit application/json content type" do
      rb = request_body("/scenarios/file-upload/avatar")
      rb["content"].as_h.has_key?(YAML::Any.new("application/json")).should be_false
    end

    it "sets required: true on the request body" do
      rb = request_body("/scenarios/file-upload/avatar")
      rb["required"].as_bool.should be_true
    end
  end

  describe "field type mapping" do
    it "maps File to type: string, format: binary" do
      props = properties("/scenarios/file-upload/avatar")
      avatar = props[YAML::Any.new("avatar")]
      avatar["type"].as_s.should eq("string")
      avatar["format"].as_s.should eq("binary")
    end

    it "maps String to type: string" do
      props = properties("/scenarios/file-upload/avatar")
      props[YAML::Any.new("display_name")]["type"].as_s.should eq("string")
    end

    it "maps Int32 to type: integer" do
      props = properties("/scenarios/file-upload/documents")
      props[YAML::Any.new("page_count")]["type"].as_s.should eq("integer")
    end

    it "maps Bool to type: boolean" do
      props = properties("/scenarios/file-upload/documents")
      props[YAML::Any.new("published")]["type"].as_s.should eq("boolean")
    end
  end

  describe "all declared fields appear" do
    it "includes all fields from the multipart NamedTuple" do
      props = properties("/scenarios/file-upload/documents")
      props.has_key?(YAML::Any.new("document")).should be_true
      props.has_key?(YAML::Any.new("title")).should be_true
      props.has_key?(YAML::Any.new("page_count")).should be_true
      props.has_key?(YAML::Any.new("published")).should be_true
    end
  end
end
