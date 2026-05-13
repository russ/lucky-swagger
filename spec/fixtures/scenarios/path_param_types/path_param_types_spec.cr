require "yaml"
require "../scenarios_helper"
require "./fixtures"

private FILTER = Regex.new("^/scenarios/path-param-types/")

private def generate_yaml
  spec = nil
  LuckySwagger.temp_config(include_routes: FILTER) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def generate_yaml_with_format_map
  spec = nil
  LuckySwagger.temp_config(
    include_routes: FILTER,
    format_map: {"token" => {type: "string", format: "uuid"}}
  ) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def path_param(yaml, path : String, method : String, name : String)
  yaml["paths"][path][method]["parameters"].as_a.find! { |p| p["name"].as_s == name }
end

describe "S-29: path_param_types" do
  describe ":id heuristic" do
    it "maps :id to integer int64" do
      param = path_param(generate_yaml, "/scenarios/path-param-types/things/{id}", "get", "id")
      param["schema"]["type"].as_s.should eq("integer")
      param["schema"]["format"].as_s.should eq("int64")
    end
  end

  describe ":x_id suffix heuristic" do
    it "maps :item_id to integer int64" do
      param = path_param(generate_yaml, "/scenarios/path-param-types/items/{item_id}", "get", "item_id")
      param["schema"]["type"].as_s.should eq("integer")
      param["schema"]["format"].as_s.should eq("int64")
    end

    it "maps both :org_id and :member_id to integer int64" do
      yaml = generate_yaml
      org = path_param(yaml, "/scenarios/path-param-types/orgs/{org_id}/members/{member_id}", "get", "org_id")
      member = path_param(yaml, "/scenarios/path-param-types/orgs/{org_id}/members/{member_id}", "get", "member_id")
      org["schema"]["type"].as_s.should eq("integer")
      org["schema"]["format"].as_s.should eq("int64")
      member["schema"]["type"].as_s.should eq("integer")
      member["schema"]["format"].as_s.should eq("int64")
    end
  end

  describe "default string fallback" do
    it "maps :token to string with no format" do
      param = path_param(generate_yaml, "/scenarios/path-param-types/tokens/{token}", "get", "token")
      param["schema"]["type"].as_s.should eq("string")
      param["schema"].as_h.has_key?(YAML::Any.new("format")).should be_false
    end
  end

  describe "format_map override" do
    it "uses format_map entry when param name matches" do
      param = path_param(generate_yaml_with_format_map, "/scenarios/path-param-types/tokens/{token}", "get", "token")
      param["schema"]["type"].as_s.should eq("string")
      param["schema"]["format"].as_s.should eq("uuid")
    end

    it "format_map does not affect id-like params" do
      param = path_param(generate_yaml_with_format_map, "/scenarios/path-param-types/things/{id}", "get", "id")
      param["schema"]["type"].as_s.should eq("integer")
      param["schema"]["format"].as_s.should eq("int64")
    end
  end
end
