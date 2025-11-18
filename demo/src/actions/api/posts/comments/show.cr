class Api::Posts::Comments::Show < ApiAction
  # Multiple path parameters
  get "/api/posts/:post_id/comments/:comment_id" do
    json({
      message: "Show comment details",
      post_id: post_id,
      comment_id: comment_id
    })
  end
end
