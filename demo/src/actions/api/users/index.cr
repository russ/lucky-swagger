class Api::Users::Index < ApiAction
  # Query parameters with different types
  param page : Int32 = 1
  param per_page : Int32 = 25
  param search : String?
  param active : Bool?
  param sort_by : String = "created_at"

  get "/api/users" do
    json({
      message: "List all users",
      params: {
        page: page,
        per_page: per_page,
        search: search,
        active: active,
        sort_by: sort_by
      }
    })
  end
end
