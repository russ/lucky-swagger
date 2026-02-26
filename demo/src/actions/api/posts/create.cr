@[LuckySwagger::Endpoint(summary: "Create post", description: "Creates a new post. Defaults to draft status if not specified.", tags: ["Posts"])]
@[LuckySwagger::RequestBody(schema: PostCreateRequest)]
@[LuckySwagger::Response(201, serializer: PostSerializer, description: "Post created successfully")]
@[LuckySwagger::Response(422, schema: LuckySwagger::ErrorSchema, description: "Validation failed")]
class Api::Posts::Create < ApiAction
  post "/api/posts" do
    json({
      message: "Post created",
      status:  "created",
    })
  end
end
