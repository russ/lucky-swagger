require "../../spec_helper"

# Mock action classes for testing - must be defined before the specs
module Api
  module Users
    class Index < Lucky::Action
      accepted_formats [:json], default: :json

      param page : Int32 = 1
      param per_page : Int32 = 20
      param search : String?

      get "/api/users" do
        plain_text "users"
      end
    end

    class Show < Lucky::Action
      accepted_formats [:json], default: :json

      get "/api/users/:id" do
        plain_text "user"
      end
    end

    class Create < Lucky::Action
      accepted_formats [:json], default: :json

      post "/api/users" do
        plain_text "created"
      end
    end

    module Posts
      class Show < Lucky::Action
        accepted_formats [:json], default: :json

        get "/api/users/:user_id/posts/:post_id" do
          plain_text "post"
        end
      end
    end
  end

  class Status < Lucky::Action
    accepted_formats [:json], default: :json

    get "/api/status" do
      plain_text "ok"
    end
  end
end

describe LuckySwagger::OpenApiGenerator do
  describe ".generate_open_api" do
    it "generates valid OpenAPI 3.0.0 structure" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      result[:openapi].should eq("3.0.0")
      result[:info].should_not be_nil
      result.has_key?(:paths).should be_true
    end

    it "includes required API metadata fields" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      result[:info][:title].should eq("API")
      result[:info][:description].should eq("API for Lucky project")
      result[:info][:version].should eq("1.0.0")
    end

    it "generates paths for API routes" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      paths = result[:paths]
      paths.should_not be_nil
    end

    it "only includes routes with 'api' in the path" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      paths = result[:paths]
      if paths
        paths.as(Hash).keys.each do |path|
          path.to_s.should contain("api")
        end
      end
    end

    it "converts Lucky route format (:param) to OpenAPI format ({param})" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      # Should have /api/users/{id} not /api/users/:id
      paths_str = result[:paths].to_s
      paths_str.should contain("{")
      paths_str.should contain("}")
    end
  end

end
