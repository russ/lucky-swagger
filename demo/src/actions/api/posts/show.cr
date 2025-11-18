class Api::Posts::Show < ApiAction
  get "/api/posts/:post_id" do
    json({
      message: "Show post details",
      post_id: post_id
    })
  end
end
