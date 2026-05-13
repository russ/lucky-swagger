require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/array-ref-items/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def post_props
  generate_yaml["components"]["schemas"]["ArrayItemPost"]["properties"].as_h
end

describe "S-30: array_ref_items" do
  describe "Array(CustomSerializer) → $ref in items" do
    it "non-nilable array property emits $ref in items" do
      tags = post_props[YAML::Any.new("tags")]
      tags["type"].as_s.should eq("array")
      tags["items"]["$ref"].as_s.should eq("#/components/schemas/ArrayItemTag")
    end

    it "nilable array property emits nullable: true and $ref in items" do
      maybe_tags = post_props[YAML::Any.new("maybe_tags")]
      maybe_tags["type"].as_s.should eq("array")
      maybe_tags["nullable"].as_bool.should be_true
      maybe_tags["items"]["$ref"].as_s.should eq("#/components/schemas/ArrayItemTag")
    end
  end

  describe "Array(primitive) → typed items" do
    it "Array(Int64) emits integer int64 items" do
      tag_ids = post_props[YAML::Any.new("tag_ids")]
      tag_ids["type"].as_s.should eq("array")
      tag_ids["items"]["type"].as_s.should eq("integer")
      tag_ids["items"]["format"].as_s.should eq("int64")
    end

    it "Array(String) emits string items" do
      labels = post_props[YAML::Any.new("labels")]
      labels["type"].as_s.should eq("array")
      labels["items"]["type"].as_s.should eq("string")
    end

    it "Array(Float64) emits number double items" do
      scores = post_props[YAML::Any.new("scores")]
      scores["type"].as_s.should eq("array")
      scores["items"]["type"].as_s.should eq("number")
      scores["items"]["format"].as_s.should eq("double")
    end
  end

  describe "referenced schema registration" do
    it "registers ArrayItemTag in components.schemas" do
      schemas = generate_yaml["components"]["schemas"].as_h
      schemas.has_key?(YAML::Any.new("ArrayItemTag")).should be_true
    end

    it "registers ArrayItemPost in components.schemas" do
      schemas = generate_yaml["components"]["schemas"].as_h
      schemas.has_key?(YAML::Any.new("ArrayItemPost")).should be_true
    end
  end
end
