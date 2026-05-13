require "yaml"
require "../scenarios_helper"
require "./fixtures"

private FILTER = Regex.new("^/scenarios/tag-config/")

private def tags_for(yaml, path : String) : Array(String)
  yaml["paths"][path]["get"]["tags"].as_a.map(&.as_s)
end

describe "S-08: tag_config" do
  it "uses default strip_prefixes and ' > ' separator" do
    spec = nil
    LuckySwagger.temp_config(include_routes: FILTER) do
      spec = LuckySwagger::OpenApiGenerator.generate_open_api
    end
    yaml = YAML.parse(spec.not_nil!.to_yaml)
    tags_for(yaml, "/scenarios/tag-config/frontend/users").should eq(["TagConfigScenario > Frontend > Users"])
  end

  it "honors a custom tag_separator" do
    spec = nil
    LuckySwagger.temp_config(include_routes: FILTER, tag_separator: " / ") do
      spec = LuckySwagger::OpenApiGenerator.generate_open_api
    end
    yaml = YAML.parse(spec.not_nil!.to_yaml)
    tags_for(yaml, "/scenarios/tag-config/frontend/users").should eq(["TagConfigScenario / Frontend / Users"])
  end

  it "honors a custom tag_strip_prefixes" do
    spec = nil
    LuckySwagger.temp_config(
      include_routes: FILTER,
      tag_strip_prefixes: ["TagConfigScenario", "Api", "V1"]
    ) do
      spec = LuckySwagger::OpenApiGenerator.generate_open_api
    end
    yaml = YAML.parse(spec.not_nil!.to_yaml)
    tags_for(yaml, "/scenarios/tag-config/api/v1/status").should eq(["default"])
  end

  it "honors a custom default_tag" do
    spec = nil
    LuckySwagger.temp_config(
      include_routes: FILTER,
      tag_strip_prefixes: ["TagConfigScenario", "Api", "V1"],
      default_tag: "general"
    ) do
      spec = LuckySwagger::OpenApiGenerator.generate_open_api
    end
    yaml = YAML.parse(spec.not_nil!.to_yaml)
    tags_for(yaml, "/scenarios/tag-config/api/v1/status").should eq(["general"])
  end
end
