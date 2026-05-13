require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/singularization/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def request_body_ref(method : String, path : String)
  generate_yaml["paths"][path][method]["requestBody"]["content"]["application/json"]["schema"]["$ref"].as_s
end

describe "S-28: singularization" do
  describe "-ies → -y (Babies → Baby)" do
    it "Create finds SaveBaby" do
      request_body_ref("post", "/scenarios/singularization/babies").should eq("#/components/schemas/SaveBaby")
    end

    it "Update also finds SaveBaby" do
      request_body_ref("put", "/scenarios/singularization/babies/{id}").should eq("#/components/schemas/SaveBaby")
    end
  end

  describe "-ses → strip es (Statuses → Status)" do
    it "Create finds SaveStatus" do
      request_body_ref("post", "/scenarios/singularization/statuses").should eq("#/components/schemas/SaveStatus")
    end
  end

  describe "-ches → strip es (Watches → Watch)" do
    it "Create finds SaveWatch" do
      request_body_ref("post", "/scenarios/singularization/watches").should eq("#/components/schemas/SaveWatch")
    end
  end

  describe "-sses → strip es (Addresses → Address)" do
    it "Create finds SaveAddress" do
      request_body_ref("post", "/scenarios/singularization/addresses").should eq("#/components/schemas/SaveAddress")
    end
  end

  describe "schema registration" do
    it "registers SaveBaby in components.schemas" do
      schemas = generate_yaml["components"]["schemas"].as_h
      schemas.has_key?(YAML::Any.new("SaveBaby")).should be_true
    end

    it "registers SaveStatus in components.schemas" do
      schemas = generate_yaml["components"]["schemas"].as_h
      schemas.has_key?(YAML::Any.new("SaveStatus")).should be_true
    end

    it "registers SaveWatch in components.schemas" do
      schemas = generate_yaml["components"]["schemas"].as_h
      schemas.has_key?(YAML::Any.new("SaveWatch")).should be_true
    end
  end
end
