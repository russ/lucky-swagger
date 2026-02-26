@[LuckySwagger::Endpoint(summary: "List users", description: "Returns a paginated list of users with optional filtering and sorting", tags: ["Users"])]
@[LuckySwagger::Response(200, serializer: UserSerializer, collection: true, description: "Paginated list of users")]
class Api::Users::Index < ApiAction
  param page : Int32 = 1
  param per_page : Int32 = 25
  param search : String?
  param active : Bool?
  param sort_by : String = "created_at"
  swagger_enum sort_by, ["created_at", "name", "email", "posts_count"]

  get "/api/users" do
    json({
      message: "List all users",
      params:  {
        page:     page,
        per_page: per_page,
        search:   search,
        active:   active,
        sort_by:  sort_by,
      },
    })
  end
end
