@[LuckySwagger::Endpoint(summary: "Get comment", description: "Returns details for a specific comment on a post", tags: ["Comments"])]
@[LuckySwagger::Response(200, serializer: CommentSerializer, description: "Comment details")]
@[LuckySwagger::Response(404, schema: LuckySwagger::ErrorSchema, description: "Comment not found")]
class Api::Posts::Comments::Show < ApiAction
  get "/api/posts/:post_id/comments/:comment_id" do
    json({
      message:    "Show comment details",
      post_id:    post_id,
      comment_id: comment_id,
    })
  end
end
