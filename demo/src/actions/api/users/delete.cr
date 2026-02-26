@[LuckySwagger::Endpoint(summary: "Delete user", description: "Permanently deletes a user and all associated data. Use soft delete endpoints instead.", tags: ["Users"], deprecated: true)]
@[LuckySwagger::Response(204, description: "User deleted successfully")]
@[LuckySwagger::Response(404, schema: LuckySwagger::ErrorSchema, description: "User not found")]
class Api::Users::Delete < ApiAction
  delete "/api/users/:user_id" do
    json({
      message: "Delete user",
      user_id: user_id,
    })
  end
end
