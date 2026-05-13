require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/save-operation-request-body/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def request_body_for(method : String, path : String)
  generate_yaml["paths"][path][method]["requestBody"]
end

private def schemas
  generate_yaml["components"]["schemas"].as_h
end

describe "S-02: save_operation_request_body" do
  describe "convention discovery" do
    it "finds SaveThing for Things::Create and references its schema" do
      body = request_body_for("post", "/scenarios/save-operation-request-body/things")
      ref = body["content"]["application/json"]["schema"]["$ref"].as_s
      ref.should eq("#/components/schemas/SaveThing")
    end

    it "also covers Things::Update" do
      body = request_body_for("put", "/scenarios/save-operation-request-body/things/{id}")
      ref = body["content"]["application/json"]["schema"]["$ref"].as_s
      ref.should eq("#/components/schemas/SaveThing")
    end

    it "registers SaveThing in components.schemas with introspected fields" do
      schemas.has_key?(YAML::Any.new("SaveThing")).should be_true
      props = schemas[YAML::Any.new("SaveThing")]["properties"].as_h
      props.has_key?(YAML::Any.new("name")).should be_true
      props.has_key?(YAML::Any.new("quantity")).should be_true
    end
  end

  describe "annotation binding" do
    it "uses @[Operation(...)] when the operation does not match the convention" do
      body = request_body_for("post", "/scenarios/save-operation-request-body/annotation-bound")
      ref = body["content"]["application/json"]["schema"]["$ref"].as_s
      ref.should eq("#/components/schemas/CustomThingyOperation")
    end

    it "registers the annotated operation's schema in components" do
      schemas.has_key?(YAML::Any.new("CustomThingyOperation")).should be_true
    end
  end

  describe "override priority" do
    it "@[RequestBody(...)] beats @[Operation(...)]" do
      body = request_body_for("post", "/scenarios/save-operation-request-body/override")
      ref = body["content"]["application/json"]["schema"]["$ref"].as_s
      ref.should eq("#/components/schemas/SaveOperationScenarioRequestOverride")
    end
  end
end
