require "../../spec_helper"
require "file_utils"
require "json"

describe LuckySwagger::GenerateOpenApi do
  it "has correct task name" do
    LuckySwagger::GenerateOpenApi.task_name.should eq("lucky_swagger.generate_open_api")
  end

  it "has a summary" do
    LuckySwagger::GenerateOpenApi.task_summary.should_not be_empty
    LuckySwagger::GenerateOpenApi.task_summary.should contain("OpenAPI")
  end

  describe "YAML generation" do
    it "generates valid OpenAPI YAML" do
      content = LuckySwagger::OpenApiGenerator.generate_yaml
      content.should contain("openapi:")
      content.should contain("3.0.0")
      YAML.parse(content)["openapi"].as_s.should eq("3.0.0")
    end

    it "creates a file on disk" do
      output_file = "./spec/tmp/test_api.yaml"
      FileUtils.rm_rf("./spec/tmp")
      Dir.mkdir_p("./spec/tmp")
      begin
        File.write(output_file, LuckySwagger::OpenApiGenerator.generate_yaml)
        File.exists?(output_file).should be_true
        YAML.parse(File.read(output_file))["openapi"].as_s.should eq("3.0.0")
      ensure
        FileUtils.rm_rf("./spec/tmp")
      end
    end
  end

  describe "T-1: JSON output" do
    it "generate_json returns valid JSON" do
      json_str = LuckySwagger::OpenApiGenerator.generate_json
      parsed = JSON.parse(json_str)
      parsed["openapi"].as_s.should eq("3.0.0")
    end

    it "JSON output contains info title" do
      parsed = JSON.parse(LuckySwagger::OpenApiGenerator.generate_json)
      parsed["info"]["title"].as_s.should eq("API")
    end

    it "JSON output contains paths key" do
      parsed = JSON.parse(LuckySwagger::OpenApiGenerator.generate_json)
      parsed.as_h.has_key?("paths").should be_true
    end
  end

  describe "T-2: alphabetically sorted paths" do
    it "paths keys are sorted alphabetically" do
      yaml = YAML.parse(LuckySwagger::OpenApiGenerator.generate_yaml)
      path_keys = yaml["paths"].as_h.keys.map(&.as_s)
      path_keys.should eq(path_keys.sort)
    end
  end

  describe "T-3: spec validation" do
    it "validate returns empty errors for a valid spec" do
      yaml = LuckySwagger::OpenApiGenerator.generate_yaml
      errors = LuckySwagger::SpecValidator.validate(yaml)
      errors.should be_empty
    end

    it "validate detects missing openapi version" do
      errors = LuckySwagger::SpecValidator.validate("info:\n  title: Test\n  version: '1.0'\npaths: {}\n")
      errors.any? { |e| e.includes?("openapi") }.should be_true
    end

    it "validate detects missing info" do
      errors = LuckySwagger::SpecValidator.validate("openapi: '3.0.0'\npaths: {}\n")
      errors.any? { |e| e.includes?("info") }.should be_true
    end

    it "validate detects dangling $ref" do
      yaml = <<-YAML
        openapi: "3.0.0"
        info:
          title: Test
          version: "1.0"
        paths:
          /foo:
            get:
              responses:
                "200":
                  content:
                    application/json:
                      schema:
                        $ref: "#/components/schemas/Ghost"
        components:
          schemas: {}
        YAML
      errors = LuckySwagger::SpecValidator.validate(yaml)
      errors.any? { |e| e.includes?("Ghost") }.should be_true
    end

    it "validate! raises on invalid spec" do
      expect_raises(Exception, /validation failed/) do
        LuckySwagger::SpecValidator.validate!("invalid: yaml\n")
      end
    end

    it "validate! passes on the generated spec" do
      LuckySwagger::SpecValidator.validate!(LuckySwagger::OpenApiGenerator.generate_yaml)
    end
  end
end
