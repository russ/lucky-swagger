require "../src/lucky-swagger"

# --- Example serializers ---

struct UserSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    property id : Int64
    property name : String
    property email : String?
    property created_at : Time
  end
end

struct PostSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    property id : Int64
    property title : String
    property body : String
    property published : Bool
    property tags : Array(String)
    property author_id : Int64
    property created_at : Time
  end
end

struct CommentSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    property id : Int64
    property text : String
    property user_id : Int64
    property post_id : Int64
  end
end

# --- Request body schemas ---

struct UserCreateRequest
  include JSON::Serializable
  property name : String
  property email : String
  property password : String
end

struct PostCreateRequest
  include JSON::Serializable
  property title : String
  property body : String
  property tags : Array(String)
  property published : Bool
end

# --- Example actions ---

module Api
  module Users
    @[LuckySwagger::Endpoint(summary: "List users", tags: ["Users"])]
    @[LuckySwagger::Response(200, serializer: UserSerializer, collection: true)]
    class Index < Lucky::Action
      include LuckySwagger::Documentable
      accepted_formats [:json], default: :json

      param page : Int32 = 1
      param per_page : Int32 = 25
      param search : String?

      get "/api/users" do
        plain_text "users"
      end
    end

    @[LuckySwagger::Endpoint(summary: "Get user by ID", tags: ["Users"])]
    @[LuckySwagger::Response(200, serializer: UserSerializer)]
    class Show < Lucky::Action
      accepted_formats [:json], default: :json

      get "/api/users/:id" do
        plain_text "user"
      end
    end

    @[LuckySwagger::Endpoint(summary: "Create a user", tags: ["Users"])]
    @[LuckySwagger::RequestBody(schema: UserCreateRequest)]
    @[LuckySwagger::Response(201, serializer: UserSerializer)]
    class Create < Lucky::Action
      accepted_formats [:json], default: :json

      post "/api/users" do
        plain_text "created"
      end
    end
  end

  module Posts
    @[LuckySwagger::Endpoint(summary: "List posts", tags: ["Posts"], description: "Returns posts with optional filtering by status")]
    @[LuckySwagger::Response(200, serializer: PostSerializer, collection: true)]
    class Index < Lucky::Action
      include LuckySwagger::Documentable
      accepted_formats [:json], default: :json

      param page : Int32 = 1
      param status : String = "all"
      swagger_enum status, ["all", "published", "draft", "archived"]

      get "/api/posts" do
        plain_text "posts"
      end
    end

    @[LuckySwagger::Endpoint(summary: "Get post by ID", tags: ["Posts"])]
    @[LuckySwagger::Response(200, serializer: PostSerializer)]
    class Show < Lucky::Action
      accepted_formats [:json], default: :json

      get "/api/posts/:id" do
        plain_text "post"
      end
    end

    @[LuckySwagger::Endpoint(summary: "Create a post", tags: ["Posts"])]
    @[LuckySwagger::RequestBody(schema: PostCreateRequest)]
    @[LuckySwagger::Response(201, serializer: PostSerializer)]
    class Create < Lucky::Action
      accepted_formats [:json], default: :json

      post "/api/posts" do
        plain_text "created"
      end
    end

    @[LuckySwagger::Endpoint(summary: "Delete a post", tags: ["Posts"])]
    @[LuckySwagger::Response(204, description: "Post deleted")]
    class Delete < Lucky::Action
      accepted_formats [:json], default: :json

      delete "/api/posts/:id" do
        plain_text "deleted"
      end
    end

    module Comments
      @[LuckySwagger::Endpoint(summary: "List comments for a post", tags: ["Comments"])]
      @[LuckySwagger::Response(200, serializer: CommentSerializer, collection: true)]
      class Index < Lucky::Action
        accepted_formats [:json], default: :json

        get "/api/posts/:post_id/comments" do
          plain_text "comments"
        end
      end
    end
  end

  @[LuckySwagger::Endpoint(summary: "Health check", tags: ["System"])]
  @[LuckySwagger::Response(200, description: "Service is healthy")]
  class Health < Lucky::Action
    accepted_formats [:json], default: :json

    get "/api/health" do
      plain_text "ok"
    end
  end
end

# Generate and print
puts YAML.dump(LuckySwagger::OpenApiGenerator.generate_open_api)
