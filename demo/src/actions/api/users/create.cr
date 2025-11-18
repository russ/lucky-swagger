class Api::Users::Create < ApiAction
  post "/api/users" do
    json({
      message: "Create a new user",
      status: "created"
    })
  end
end
