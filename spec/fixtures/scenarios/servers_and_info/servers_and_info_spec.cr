require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def filter
  Regex.new("^/scenarios/servers-and-info/")
end

private def base_yaml
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

describe "S-18: servers_and_info" do
  describe "EF-12: per-operation servers override" do
    it "emits servers array on annotated operation" do
      op = base_yaml["paths"]["/scenarios/servers-and-info/uploads"]["post"]
      op.as_h.has_key?(YAML::Any.new("servers")).should be_true
      op["servers"][0]["url"].as_s.should eq("https://upload.example.com")
      op["servers"][0]["description"].as_s.should eq("Upload CDN")
    end

    it "emits multiple servers when more than one declared" do
      op = base_yaml["paths"]["/scenarios/servers-and-info/multi"]["get"]
      op["servers"].as_a.size.should eq(2)
      op["servers"][0]["url"].as_s.should eq("https://a.example.com")
      op["servers"][1]["url"].as_s.should eq("https://b.example.com")
    end

    it "omits description when not provided in server entry" do
      op = base_yaml["paths"]["/scenarios/servers-and-info/multi"]["get"]
      op["servers"][0].as_h.has_key?(YAML::Any.new("description")).should be_false
    end

    it "does not emit servers on unannotated operations" do
      op = base_yaml["paths"]["/scenarios/servers-and-info/plain"]["get"]
      op.as_h.has_key?(YAML::Any.new("servers")).should be_false
    end
  end

  describe "EF-15: info.termsOfService" do
    it "emits termsOfService when configured" do
      spec = nil
      LuckySwagger.temp_config(include_routes: filter, terms_of_service: "https://example.com/tos") do
        spec = LuckySwagger::OpenApiGenerator.generate_open_api
      end
      yaml = YAML.parse(spec.not_nil!.to_yaml)
      yaml["info"].as_h.has_key?(YAML::Any.new("termsOfService")).should be_true
      yaml["info"]["termsOfService"].as_s.should eq("https://example.com/tos")
    end

    it "omits termsOfService when not configured" do
      base_yaml["info"].as_h.has_key?(YAML::Any.new("termsOfService")).should be_false
    end
  end

  describe "EF-15: info.contact" do
    it "emits contact object when configured" do
      spec = nil
      LuckySwagger.temp_config(include_routes: filter, contact: {name: "Support", email: "support@example.com", url: nil}) do
        spec = LuckySwagger::OpenApiGenerator.generate_open_api
      end
      yaml = YAML.parse(spec.not_nil!.to_yaml)
      yaml["info"].as_h.has_key?(YAML::Any.new("contact")).should be_true
      yaml["info"]["contact"]["name"].as_s.should eq("Support")
    end

    it "omits contact when not configured" do
      base_yaml["info"].as_h.has_key?(YAML::Any.new("contact")).should be_false
    end
  end

  describe "EF-15: info.license" do
    it "emits license object when configured" do
      spec = nil
      LuckySwagger.temp_config(include_routes: filter, license: {name: "MIT", url: "https://opensource.org/licenses/MIT"}) do
        spec = LuckySwagger::OpenApiGenerator.generate_open_api
      end
      yaml = YAML.parse(spec.not_nil!.to_yaml)
      yaml["info"].as_h.has_key?(YAML::Any.new("license")).should be_true
      yaml["info"]["license"]["name"].as_s.should eq("MIT")
      yaml["info"]["license"]["url"].as_s.should eq("https://opensource.org/licenses/MIT")
    end

    it "omits license when not configured" do
      base_yaml["info"].as_h.has_key?(YAML::Any.new("license")).should be_false
    end
  end
end
