require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/serializer-return-inference/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def responses_for(method : String, path : String)
  generate_yaml["paths"][path][method]["responses"].as_h
end

private def schemas
  generate_yaml["components"]["schemas"].as_h
end

describe "S-03: serializer_return_inference" do
  describe "convention discovery" do
    it "infers 200 + $ref for Show actions matching <Singular>Serializer" do
      responses = responses_for("get", "/scenarios/serializer-return-inference/widgets/{id}")
      ok = responses[YAML::Any.new("200")]
      ok["content"]["application/json"]["schema"]["$ref"].as_s.should eq("#/components/schemas/Widget")
    end

    it "infers 201 + auto-422 for Create actions" do
      responses = responses_for("post", "/scenarios/serializer-return-inference/widgets")
      responses.has_key?(YAML::Any.new("201")).should be_true
      responses.has_key?(YAML::Any.new("422")).should be_true
      responses[YAML::Any.new("201")]["content"]["application/json"]["schema"]["$ref"].as_s.should eq("#/components/schemas/Widget")
    end

    it "infers 200 + auto-422 for Update actions" do
      responses = responses_for("put", "/scenarios/serializer-return-inference/widgets/{id}")
      responses.has_key?(YAML::Any.new("200")).should be_true
      responses.has_key?(YAML::Any.new("422")).should be_true
      responses[YAML::Any.new("200")]["content"]["application/json"]["schema"]["$ref"].as_s.should eq("#/components/schemas/Widget")
    end

    it "does NOT fire for Delete actions (default 204 still applies)" do
      responses = responses_for("delete", "/scenarios/serializer-return-inference/widgets/{id}")
      responses.has_key?(YAML::Any.new("204")).should be_true
      responses.has_key?(YAML::Any.new("200")).should be_false
    end

    it "registers the inferred serializer's schema in components" do
      schemas.has_key?(YAML::Any.new("Widget")).should be_true
      props = schemas[YAML::Any.new("Widget")]["properties"].as_h
      props.has_key?(YAML::Any.new("name")).should be_true
      props.has_key?(YAML::Any.new("color")).should be_true
    end
  end

  describe "fall-through" do
    it "leaves actions with no matching serializer at the default response" do
      responses = responses_for("get", "/scenarios/serializer-return-inference/orphans/{id}")
      responses.has_key?(YAML::Any.new("200")).should be_true
      # Default is type: object, not a $ref
      schema = responses[YAML::Any.new("200")]["content"]["application/json"]["schema"]
      schema.as_h.has_key?(YAML::Any.new("$ref")).should be_false
    end
  end

  describe "override priority" do
    it "explicit @[Response(...)] beats convention" do
      responses = responses_for("get", "/scenarios/serializer-return-inference/widgets/{id}/overridden")
      ref = responses[YAML::Any.new("200")]["content"]["application/json"]["schema"]["$ref"].as_s
      ref.should eq("#/components/schemas/WidgetExplicit")
    end
  end
end
