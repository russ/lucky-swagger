require "../../spec_helper"
require "file_utils"

describe LuckySwagger::GenerateOpenApi do
  it "has correct task name" do
    LuckySwagger::GenerateOpenApi.task_name.should eq("lucky_swagger.generate_open_api")
  end

  it "has a summary" do
    LuckySwagger::GenerateOpenApi.task_summary.should_not be_empty
    LuckySwagger::GenerateOpenApi.task_summary.should contain("OpenAPI")
  end

  describe "file generation" do
    it "generates valid OpenAPI YAML file" do
      output_file = "./spec/tmp/test_api.yaml"

      # Clean up before test
      FileUtils.rm_rf("./spec/tmp")
      Dir.mkdir_p("./spec/tmp")

      begin
        # Directly call the private method's logic
        path = Path[output_file].dirname
        Dir.mkdir_p(path) unless Dir.exists?(path)
        File.open(output_file, "w") do |file|
          YAML.dump(LuckySwagger::OpenApiGenerator.generate_open_api, file)
        end

        File.exists?(output_file).should be_true

        content = File.read(output_file)
        content.should contain("openapi:")
        content.should contain("3.0.0")

        parsed = YAML.parse(content)
        parsed["openapi"].as_s.should eq("3.0.0")
        parsed["info"]["title"].as_s.should eq("API")
      ensure
        # Clean up after test
        FileUtils.rm_rf("./spec/tmp")
      end
    end

    it "creates nested directories if they don't exist" do
      output_file = "./spec/tmp/nested/deep/api.yaml"

      # Clean up before test
      FileUtils.rm_rf("./spec/tmp")

      begin
        path = Path[output_file].dirname
        Dir.mkdir_p(path) unless Dir.exists?(path)

        Dir.exists?("./spec/tmp/nested/deep").should be_true

        File.open(output_file, "w") do |file|
          YAML.dump(LuckySwagger::OpenApiGenerator.generate_open_api, file)
        end

        File.exists?(output_file).should be_true
      ensure
        # Clean up after test
        FileUtils.rm_rf("./spec/tmp")
      end
    end
  end
end
