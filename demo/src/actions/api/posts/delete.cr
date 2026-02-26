@[LuckySwagger::Endpoint(summary: "Delete post", description: "Permanently deletes a post and all its comments", tags: ["Posts"])]
@[LuckySwagger::Response(204, description: "Post deleted successfully")]
@[LuckySwagger::Response(404, schema: LuckySwagger::ErrorSchema, description: "Post not found")]
class Api::Posts::Delete < ApiAction
  delete "/api/posts/:post_id" do
    json({
      message: "Post deleted",
      post_id: post_id,
    })
  end
end
