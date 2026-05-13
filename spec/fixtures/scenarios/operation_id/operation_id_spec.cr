require "yaml"
require "../scenarios_helper"
require "./fixtures"

private FILTER = Regex.new("^/scenarios/operation-id/")

private def yaml_camel_case
  spec = nil
  LuckySwagger.temp_config(include_routes: FILTER, tag_strip_prefixes: ["OperationIdScenario"]) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def yaml_snake_case
  spec = nil
  LuckySwagger.temp_config(
    include_routes: FILTER,
    tag_strip_prefixes: ["OperationIdScenario"],
    operation_id_style: "snake_case"
  ) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

describe "S-27: operation_id" do
  describe "camelCase (default)" do
    it "generates camelCase operationId for Index" do
      op = yaml_camel_case["paths"]["/scenarios/operation-id/widgets"]["get"]
      op["operationId"].as_s.should eq("widgetsIndex")
    end

    it "generates camelCase operationId for Show" do
      op = yaml_camel_case["paths"]["/scenarios/operation-id/widgets/{id}"]["get"]
      op["operationId"].as_s.should eq("widgetsShow")
    end
  end

  describe "snake_case style" do
    it "generates snake_case operationId when configured" do
      op = yaml_snake_case["paths"]["/scenarios/operation-id/widgets"]["get"]
      op["operationId"].as_s.should eq("widgets_index")
    end
  end

  describe "explicit override" do
    it "uses @[Endpoint(operation_id:)] value regardless of style" do
      op = yaml_camel_case["paths"]["/scenarios/operation-id/widgets"]["post"]
      op["operationId"].as_s.should eq("createWidgetExplicit")
    end

    it "explicit override also beats snake_case style" do
      op = yaml_snake_case["paths"]["/scenarios/operation-id/widgets"]["post"]
      op["operationId"].as_s.should eq("createWidgetExplicit")
    end
  end
end
