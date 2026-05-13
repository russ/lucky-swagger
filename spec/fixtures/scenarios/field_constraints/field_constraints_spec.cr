require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/field-constraints/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def props
  generate_yaml["components"]["schemas"]["ConstrainedPost"]["properties"].as_h
end

describe "S-19: field_constraints (IR-9 through IR-12)" do
  describe "IR-10: enum constraint via field macro" do
    it "emits enum array for status field" do
      props[YAML::Any.new("status")].as_h.has_key?(YAML::Any.new("enum")).should be_true
      props[YAML::Any.new("status")]["enum"].as_a.map(&.as_s).should eq(["draft", "published", "archived"])
    end

    it "emits default value alongside enum" do
      props[YAML::Any.new("status")]["default"].as_s.should eq("draft")
    end
  end

  describe "IR-12: string size constraints" do
    it "emits maxLength on title" do
      props[YAML::Any.new("title")]["maxLength"].as_i.should eq(200)
    end

    it "emits minLength on title" do
      props[YAML::Any.new("title")]["minLength"].as_i.should eq(1)
    end
  end

  describe "IR-12: format constraint" do
    it "emits format on author_email" do
      props[YAML::Any.new("author_email")]["format"].as_s.should eq("email")
    end

    it "emits format on nullable published_at" do
      props[YAML::Any.new("published_at")]["format"].as_s.should eq("date-time")
    end
  end

  describe "IR-11: numeric range + default" do
    it "emits minimum on priority" do
      props[YAML::Any.new("priority")]["minimum"].as_i.should eq(1)
    end

    it "emits maximum on priority" do
      props[YAML::Any.new("priority")]["maximum"].as_i.should eq(5)
    end

    it "emits default on priority" do
      props[YAML::Any.new("priority")]["default"].as_i.should eq(3)
    end
  end

  describe "float range constraints" do
    it "emits minimum on score" do
      props[YAML::Any.new("score")]["minimum"].as_f.should eq(0.0)
    end

    it "emits maximum on score" do
      props[YAML::Any.new("score")]["maximum"].as_f.should eq(100.0)
    end
  end

  describe "IR-9: required vs optional via nilability" do
    it "includes non-nilable fields in required array" do
      required = generate_yaml["components"]["schemas"]["ConstrainedPost"]["required"].as_a.map(&.as_s)
      required.should contain("id")
      required.should contain("status")
      required.should contain("title")
    end

    it "excludes nilable fields from required array" do
      required = generate_yaml["components"]["schemas"]["ConstrainedPost"]["required"].as_a.map(&.as_s)
      required.should_not contain("published_at")
      required.should_not contain("body")
    end
  end

  describe "plain property with no constraints" do
    it "does not emit constraint keys on unconstrained body field" do
      body_props = props[YAML::Any.new("body")].as_h
      body_props.has_key?(YAML::Any.new("maxLength")).should be_false
      body_props.has_key?(YAML::Any.new("enum")).should be_false
    end
  end
end
