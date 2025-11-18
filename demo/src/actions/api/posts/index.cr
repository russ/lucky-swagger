class Api::Posts::Index < ApiAction
  # Query parameters for filtering posts
  param author_id : Int32?
  param status : String = "published"
  param limit : Int32 = 10

  get "/api/posts" do
    json({
      message: "List all posts",
      params: {
        author_id: author_id,
        status: status,
        limit: limit
      }
    })
  end
end
