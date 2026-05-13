require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/non-json-responses/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def response_200(path : String, method : String = "get")
  generate_yaml["paths"][path][method]["responses"]["200"]
end

describe "S-13: non_json_responses" do
  describe "CSV content type" do
    it "emits text/csv as the content type" do
      resp = response_200("/scenarios/non-json-responses/export.csv")
      resp["content"].as_h.has_key?(YAML::Any.new("text/csv")).should be_true
    end

    it "does not emit application/json for a CSV response" do
      resp = response_200("/scenarios/non-json-responses/export.csv")
      resp["content"].as_h.has_key?(YAML::Any.new("application/json")).should be_false
    end

    it "emits the description when provided" do
      resp = response_200("/scenarios/non-json-responses/export.csv")
      resp["description"].as_s.should eq("CSV export")
    end

    it "emits type: string as the schema" do
      resp = response_200("/scenarios/non-json-responses/export.csv")
      resp["content"]["text/csv"]["schema"]["type"].as_s.should eq("string")
    end
  end

  describe "plain text content type" do
    it "emits text/plain as the content type" do
      resp = response_200("/scenarios/non-json-responses/ping")
      resp["content"].as_h.has_key?(YAML::Any.new("text/plain")).should be_true
    end
  end

  describe "custom binary content type" do
    it "emits application/pdf as the content type" do
      resp = response_200("/scenarios/non-json-responses/report.pdf")
      resp["content"].as_h.has_key?(YAML::Any.new("application/pdf")).should be_true
    end

    it "emits the description for pdf response" do
      resp = response_200("/scenarios/non-json-responses/report.pdf")
      resp["description"].as_s.should eq("PDF report")
    end
  end

  describe "mixed non-JSON + JSON responses" do
    it "emits text/csv for the 200 response" do
      resp = response_200("/scenarios/non-json-responses/export-with-errors", "post")
      resp["content"].as_h.has_key?(YAML::Any.new("text/csv")).should be_true
    end

    it "emits application/json for the 422 response" do
      responses = generate_yaml["paths"]["/scenarios/non-json-responses/export-with-errors"]["post"]["responses"].as_h
      responses.has_key?(YAML::Any.new("422")).should be_true
      responses[YAML::Any.new("422")]["content"]["application/json"]["schema"]["$ref"].as_s.should eq("#/components/schemas/Error")
    end
  end
end
