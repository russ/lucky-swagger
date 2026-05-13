module FileUploadScenario
  # File + text field upload
  @[LuckySwagger::RequestBody(multipart: {avatar: File, display_name: String})]
  class AvatarUpload < ScenarioAction
    post "/scenarios/file-upload/avatar" do
      plain_text "ok"
    end
  end

  # Multi-file with mixed types
  @[LuckySwagger::RequestBody(multipart: {document: File, title: String, page_count: Int32, published: Bool})]
  class DocumentUpload < ScenarioAction
    post "/scenarios/file-upload/documents" do
      plain_text "ok"
    end
  end
end
