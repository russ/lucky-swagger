@[LuckySwagger::Endpoint(summary: "Update post", description: "Updates an existing post. Only provided fields are changed.", tags: ["Posts"])]
@[LuckySwagger::RequestBody(schema: PostUpdateRequest)]
@[LuckySwagger::Response(200, serializer: PostSerializer, description: "Post updated successfully")]
@[LuckySwagger::Response(404, schema: LuckySwagger::ErrorSchema, description: "Post not found")]
@[LuckySwagger::Response(422, schema: LuckySwagger::ErrorSchema, description: "Validation failed")]
class Api::Posts::Update < ApiAction
  put "/api/posts/:post_id" do
    json({
      message: "Post updated",
      post_id: post_id,
    })
  end
end
