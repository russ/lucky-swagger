module ServersAndInfoScenario
  # EF-12: per-operation servers override (url + description)
  @[LuckySwagger::Endpoint(servers: [{url: "https://upload.example.com", description: "Upload CDN"}])]
  class UploadAction < ScenarioAction
    post "/scenarios/servers-and-info/uploads" do
      plain_text "ok"
    end
  end

  # EF-12: multiple servers on one operation
  @[LuckySwagger::Endpoint(servers: [{url: "https://a.example.com"}, {url: "https://b.example.com", description: "Replica"}])]
  class MultiServerAction < ScenarioAction
    get "/scenarios/servers-and-info/multi" do
      plain_text "ok"
    end
  end

  # No servers override — confirms nothing bleeds through
  class PlainAction < ScenarioAction
    get "/scenarios/servers-and-info/plain" do
      plain_text "ok"
    end
  end
end
