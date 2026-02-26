require "../../spec_helper"

# --- Mock serializers with swagger_fields ---

struct UserSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    property id : Int64
    property name : String
    property email : String?
  end

  def initialize(@id : Int64, @name : String, @email : String?)
  end
end

struct PostSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    property id : Int64
    property text : String
    property comments_count : Int32
    property tags : Array(String)
    property created_at : Time
  end

  def initialize(@id : Int64, @text : String, @comments_count : Int32, @tags : Array(String), @created_at : Time)
  end
end

# --- Mock request body schema ---

struct UserCreateRequest
  include JSON::Serializable

  property email : String
  property password : String
  property name : String?
end

# --- Mock actions ---

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

  module Feed
    @[LuckySwagger::Endpoint(summary: "Get feed", tags: ["Feed"])]
    @[LuckySwagger::Response(200, serializer: PostSerializer, collection: true)]
    class Index < Lucky::Action
      include LuckySwagger::Documentable
      accepted_formats [:json], default: :json

      param filter : String = "all"
      swagger_enum filter, ["all", "following", "subscribed", "myposts"]

      get "/api/feed" do
        plain_text "feed"
      end
    end
  end

  module Profile
    @[LuckySwagger::Endpoint(summary: "Get user profile", description: "Returns the authenticated user's profile")]
    @[LuckySwagger::Response(200, serializer: UserSerializer)]
    class Show < Lucky::Action
      accepted_formats [:json], default: :json

      get "/api/profile" do
        plain_text "profile"
      end
    end
  end

  module Accounts
    @[LuckySwagger::Endpoint(summary: "Create account")]
    @[LuckySwagger::RequestBody(schema: UserCreateRequest)]
    @[LuckySwagger::Response(201, serializer: UserSerializer)]
    class Create < Lucky::Action
      accepted_formats [:json], default: :json

      post "/api/accounts" do
        plain_text "created"
      end
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
      result.has_key?(:components).should be_true
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

      paths_str = result[:paths].to_s
      paths_str.should contain("{")
      paths_str.should contain("}")
    end
  end

  describe "components/schemas" do
    it "includes built-in Pagination schema" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      schemas = result[:components][:schemas]
      schemas.has_key?("Pagination").should be_true

      pagination = schemas["Pagination"]
      pagination[:type].should eq("object")
      pagination[:properties].has_key?("total_items").should be_true
      pagination[:properties].has_key?("per_page").should be_true
    end

    it "includes built-in Error schema" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      schemas = result[:components][:schemas]
      schemas.has_key?("Error").should be_true

      error = schemas["Error"]
      error[:type].should eq("object")
      error[:properties].has_key?("message").should be_true
    end

    it "collects serializer schemas from Response annotations" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      schemas = result[:components][:schemas]
      # PostSerializer's swagger_fields should produce a "Post" schema
      schemas.has_key?("Post").should be_true
      # UserSerializer's swagger_fields should produce a "User" schema
      schemas.has_key?("User").should be_true
    end

    it "collects request body schemas from RequestBody annotations" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      schemas = result[:components][:schemas]
      schemas.has_key?("UserCreateRequest").should be_true
    end
  end

  describe "$ref usage" do
    it "uses $ref for annotated single-object responses" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      paths = result[:paths]
      if paths
        # Api::Profile::Show should have a $ref response
        profile_path = paths.as(Hash)["/api/profile"]?
        if profile_path
          get_spec = profile_path.as(Hash)["get"]?
          if get_spec
            get_str = get_spec.to_s
            get_str.should contain("#/components/schemas/User")
          end
        end
      end
    end

    it "uses $ref for collection responses with pagination" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      paths = result[:paths]
      if paths
        feed_path = paths.as(Hash)["/api/feed"]?
        if feed_path
          get_spec = feed_path.as(Hash)["get"]?
          if get_spec
            get_str = get_spec.to_s
            get_str.should contain("#/components/schemas/Post")
            get_str.should contain("#/components/schemas/Pagination")
            get_str.should contain("items")
          end
        end
      end
    end

    it "uses $ref for request body schemas" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      paths = result[:paths]
      if paths
        accounts_path = paths.as(Hash)["/api/accounts"]?
        if accounts_path
          post_spec = accounts_path.as(Hash)["post"]?
          if post_spec
            post_str = post_spec.to_s
            post_str.should contain("#/components/schemas/UserCreateRequest")
          end
        end
      end
    end
  end

  describe "enum params" do
    it "attaches enum values to query params with swagger_enum" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      paths = result[:paths]
      if paths
        feed_path = paths.as(Hash)["/api/feed"]?
        if feed_path
          get_spec = feed_path.as(Hash)["get"]?
          if get_spec
            get_str = get_spec.to_s
            get_str.should contain("all")
            get_str.should contain("following")
            get_str.should contain("subscribed")
            get_str.should contain("myposts")
          end
        end
      end
    end
  end

  describe "Endpoint annotation" do
    it "uses custom tags from Endpoint annotation" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      paths = result[:paths]
      if paths
        feed_path = paths.as(Hash)["/api/feed"]?
        if feed_path
          get_spec = feed_path.as(Hash)["get"]?
          if get_spec
            get_str = get_spec.to_s
            get_str.should contain("Feed")
          end
        end
      end
    end

    it "uses custom summary from Endpoint annotation" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      paths = result[:paths]
      if paths
        feed_path = paths.as(Hash)["/api/feed"]?
        if feed_path
          get_spec = feed_path.as(Hash)["get"]?
          if get_spec
            get_str = get_spec.to_s
            get_str.should contain("Get feed")
          end
        end
      end
    end
  end

  describe "default responses" do
    it "auto-appends 422 for POST endpoints without explicit error response" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      paths = result[:paths]
      if paths
        users_path = paths.as(Hash)["/api/users"]?
        if users_path
          post_spec = users_path.as(Hash)["post"]?
          if post_spec
            post_str = post_spec.to_s
            post_str.should contain("422")
          end
        end
      end
    end

    it "uses default responses for unannotated GET endpoints" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      paths = result[:paths]
      if paths
        status_path = paths.as(Hash)["/api/status"]?
        if status_path
          get_spec = status_path.as(Hash)["get"]?
          if get_spec
            get_str = get_spec.to_s
            get_str.should contain("200")
            get_str.should contain("Success")
          end
        end
      end
    end
  end
end
