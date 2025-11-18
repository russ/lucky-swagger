class Api::Users::Update < ApiAction
  put "/api/users/:user_id" do
    json({
      message: "Update user",
      user_id: user_id
    })
  end
end
