class Api::Users::Show < ApiAction
  # Path parameter
  get "/api/users/:user_id" do
    json({
      message: "Show user details",
      user_id: user_id
    })
  end
end
