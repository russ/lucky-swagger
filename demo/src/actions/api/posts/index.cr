@[LuckySwagger::Endpoint(summary: "List posts", description: "Returns a list of posts with optional filtering by author and status", tags: ["Posts"], security: "none")]
@[LuckySwagger::Response(200, serializer: PostSerializer, collection: true, description: "Paginated list of posts")]
class Api::Posts::Index < ApiAction
  param author_id : Int32?
  param status : String = "published"
  param limit : Int32 = 10
  param page : Int32 = 1
  swagger_enum status, ["published", "draft", "archived"]

  get "/api/posts" do
    json({
      message: "List all posts",
      params:  {
        author_id: author_id,
        status:    status,
        limit:     limit,
        page:      page,
      },
    })
  end
end
