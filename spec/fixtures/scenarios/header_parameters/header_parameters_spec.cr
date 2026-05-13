require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/header-parameters/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def params_for(method : String, path : String)
  generate_yaml["paths"][path][method]["parameters"].as_a
end

describe "S-10: header_parameters" do
  describe "header params on annotated action" do
    it "includes both header params in the parameters list" do
      params = params_for("get", "/scenarios/header-parameters/items/{id}")
      header_names = params.select { |p| p["in"].as_s == "header" }.map { |p| p["name"].as_s }
      header_names.should contain("X-Request-ID")
      header_names.should contain("X-Api-Version")
    end

    it "emits in: header for header params" do
      params = params_for("get", "/scenarios/header-parameters/items/{id}")
      x_req = params.find! { |p| p["name"].as_s == "X-Request-ID" }
      x_req["in"].as_s.should eq("header")
    end

    it "maps String type to schema type: string" do
      params = params_for("get", "/scenarios/header-parameters/items/{id}")
      x_req = params.find! { |p| p["name"].as_s == "X-Request-ID" }
      x_req["schema"]["type"].as_s.should eq("string")
    end

    it "maps Int32 type to schema type: integer" do
      params = params_for("get", "/scenarios/header-parameters/items/{id}")
      x_ver = params.find! { |p| p["name"].as_s == "X-Api-Version" }
      x_ver["schema"]["type"].as_s.should eq("integer")
    end

    it "respects required: false" do
      params = params_for("get", "/scenarios/header-parameters/items/{id}")
      x_req = params.find! { |p| p["name"].as_s == "X-Request-ID" }
      x_req["required"].as_bool.should be_false
    end

    it "respects required: true" do
      params = params_for("get", "/scenarios/header-parameters/items/{id}")
      x_ver = params.find! { |p| p["name"].as_s == "X-Api-Version" }
      x_ver["required"].as_bool.should be_true
    end

    it "emits description when provided" do
      params = params_for("get", "/scenarios/header-parameters/items/{id}")
      x_req = params.find! { |p| p["name"].as_s == "X-Request-ID" }
      x_req["description"].as_s.should eq("Client trace ID")
    end

    it "does not emit description when omitted" do
      params = params_for("get", "/scenarios/header-parameters/items/{id}")
      x_ver = params.find! { |p| p["name"].as_s == "X-Api-Version" }
      x_ver.as_h.has_key?(YAML::Any.new("description")).should be_false
    end

    it "still includes the path param alongside header params" do
      params = params_for("get", "/scenarios/header-parameters/items/{id}")
      path_param = params.find! { |p| p["in"].as_s == "path" }
      path_param["name"].as_s.should eq("id")
    end
  end

  describe "action without header annotations" do
    it "only emits path params (no header params)" do
      params = params_for("get", "/scenarios/header-parameters/plain/{id}")
      header_params = params.select { |p| p["in"].as_s == "header" }
      header_params.should be_empty
    end
  end
end
