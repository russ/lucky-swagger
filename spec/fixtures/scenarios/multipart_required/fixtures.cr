module MultipartRequiredScenario
  # One required field out of three
  @[LuckySwagger::RequestBody(multipart: {avatar: File, bio: String, website: String}, required: [:avatar])]
  class UpdateProfile < ScenarioAction
    put "/scenarios/multipart-required/profile" do
      plain_text "ok"
    end
  end

  # Multiple required fields
  @[LuckySwagger::RequestBody(multipart: {document: File, title: String, summary: String}, required: [:document, :title])]
  class CreateDocument < ScenarioAction
    post "/scenarios/multipart-required/documents" do
      plain_text "ok"
    end
  end

  # No required key — required array should be absent from output
  @[LuckySwagger::RequestBody(multipart: {name: String, note: String})]
  class CreateNote < ScenarioAction
    post "/scenarios/multipart-required/notes" do
      plain_text "ok"
    end
  end
end
