@[LuckySwagger::Endpoint(summary: "List comments", description: "Returns comments for a specific post. Optionally include soft-deleted comments.", tags: ["Comments"])]
@[LuckySwagger::Response(200, serializer: CommentSerializer, collection: true, description: "Paginated list of comments")]
class Api::Posts::Comments::Index < ApiAction
  param include_deleted : Bool = false
  param page : Int32 = 1
  param per_page : Int32 = 25

  get "/api/posts/:post_id/comments" do
    json({
      message:         "List comments for post",
      post_id:         post_id,
      include_deleted: include_deleted,
    })
  end
end
