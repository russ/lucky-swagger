require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/cookie-parameters/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def params_for(method : String, path : String)
  generate_yaml["paths"][path][method]["parameters"].as_a
end

describe "S-11: cookie_parameters" do
  describe "cookie-only action" do
    it "emits in: cookie for all declared cookie params" do
      params = params_for("get", "/scenarios/cookie-parameters/items/{id}")
      cookie_params = params.select { |p| p["in"].as_s == "cookie" }
      cookie_params.size.should eq(2)
    end

    it "includes session_id and theme cookies" do
      params = params_for("get", "/scenarios/cookie-parameters/items/{id}")
      names = params.select { |p| p["in"].as_s == "cookie" }.map { |p| p["name"].as_s }
      names.should contain("session_id")
      names.should contain("theme")
    end

    it "respects required: true on cookie param" do
      params = params_for("get", "/scenarios/cookie-parameters/items/{id}")
      session = params.find! { |p| p["name"].as_s == "session_id" }
      session["required"].as_bool.should be_true
    end

    it "respects required: false on cookie param" do
      params = params_for("get", "/scenarios/cookie-parameters/items/{id}")
      theme = params.find! { |p| p["name"].as_s == "theme" }
      theme["required"].as_bool.should be_false
    end

    it "emits description when provided" do
      params = params_for("get", "/scenarios/cookie-parameters/items/{id}")
      session = params.find! { |p| p["name"].as_s == "session_id" }
      session["description"].as_s.should eq("Session token")
    end

    it "does not emit description when omitted" do
      params = params_for("get", "/scenarios/cookie-parameters/items/{id}")
      theme = params.find! { |p| p["name"].as_s == "theme" }
      theme.as_h.has_key?(YAML::Any.new("description")).should be_false
    end
  end

  describe "action with both header and cookie params" do
    it "emits header param with in: header" do
      params = params_for("get", "/scenarios/cookie-parameters/mixed/{id}")
      header_params = params.select { |p| p["in"].as_s == "header" }
      header_params.map { |p| p["name"].as_s }.should contain("X-Request-ID")
    end

    it "emits cookie param with in: cookie" do
      params = params_for("get", "/scenarios/cookie-parameters/mixed/{id}")
      cookie_params = params.select { |p| p["in"].as_s == "cookie" }
      cookie_params.map { |p| p["name"].as_s }.should contain("session_id")
    end

    it "includes path param alongside header and cookie params" do
      params = params_for("get", "/scenarios/cookie-parameters/mixed/{id}")
      params.map { |p| p["in"].as_s }.should contain("path")
    end
  end
end
