@[LuckySwagger::Endpoint(summary: "Create comment", description: "Adds a new comment to a post. Supports threaded replies via parent_id.", tags: ["Comments"])]
@[LuckySwagger::RequestBody(schema: CommentCreateRequest)]
@[LuckySwagger::Response(201, serializer: CommentSerializer, description: "Comment created successfully")]
@[LuckySwagger::Response(404, schema: LuckySwagger::ErrorSchema, description: "Post not found")]
@[LuckySwagger::Response(422, schema: LuckySwagger::ErrorSchema, description: "Validation failed")]
class Api::Posts::Comments::Create < ApiAction
  post "/api/posts/:post_id/comments" do
    json({
      message: "Comment created",
      post_id: post_id,
    })
  end
end
