class Api::Users::Delete < ApiAction
  delete "/api/users/:user_id" do
    json({
      message: "Delete user",
      user_id: user_id
    })
  end
end
