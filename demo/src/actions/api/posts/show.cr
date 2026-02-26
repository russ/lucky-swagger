@[LuckySwagger::Endpoint(summary: "Get post", description: "Returns detailed information for a specific post including author and tags", tags: ["Posts"])]
@[LuckySwagger::Response(200, serializer: PostSerializer, description: "Post details")]
@[LuckySwagger::Response(404, schema: LuckySwagger::ErrorSchema, description: "Post not found")]
class Api::Posts::Show < ApiAction
  get "/api/posts/:post_id" do
    json({
      message: "Show post details",
      post_id: post_id,
    })
  end
end
