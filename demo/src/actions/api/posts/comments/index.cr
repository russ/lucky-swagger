class Api::Posts::Comments::Index < ApiAction
  # Nested resource with multiple path parameters
  param include_deleted : Bool = false

  get "/api/posts/:post_id/comments" do
    json({
      message: "List comments for post",
      post_id: post_id,
      include_deleted: include_deleted
    })
  end
end
