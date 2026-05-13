require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/humanized-summary/")
  spec = nil
  LuckySwagger.temp_config(include_routes: filter) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def summary(path : String, method : String)
  generate_yaml["paths"][path][method]["summary"].as_s
end

describe "S-31: humanized_summary" do
  describe "standard CRUD action names" do
    it "Index → 'List <resource>'" do
      summary("/scenarios/humanized-summary/widgets", "get").should eq("List widgets")
    end

    it "Show → 'Get <singular resource>'" do
      summary("/scenarios/humanized-summary/widgets/{id}", "get").should eq("Get widget")
    end

    it "Create → 'Create <singular resource>'" do
      summary("/scenarios/humanized-summary/widgets", "post").should eq("Create widget")
    end

    it "Update → 'Update <singular resource>'" do
      summary("/scenarios/humanized-summary/widgets/{id}", "put").should eq("Update widget")
    end

    it "Destroy → 'Delete <singular resource>'" do
      summary("/scenarios/humanized-summary/widgets/{id}", "delete").should eq("Delete widget")
    end
  end

  describe "non-standard action names" do
    it "BulkArchive → humanized with resource context" do
      summary("/scenarios/humanized-summary/widgets/bulk-archive", "post").should eq("bulk archive widgets")
    end
  end

  describe "explicit summary override" do
    it "@[Endpoint(summary:)] beats auto-generation" do
      summary("/scenarios/humanized-summary/custom", "get").should eq("My custom summary")
    end
  end
end
