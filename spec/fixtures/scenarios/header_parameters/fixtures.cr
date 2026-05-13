module HeaderParametersScenario
  # Multiple headers: one required with description, one optional typed, one plain
  @[LuckySwagger::HeaderParam(name: "X-Request-ID", type: String, required: false, description: "Client trace ID")]
  @[LuckySwagger::HeaderParam(name: "X-Api-Version", type: Int32, required: true)]
  class HeaderRichAction < ScenarioAction
    get "/scenarios/header-parameters/items/:id" do
      plain_text "ok"
    end
  end

  # No header annotations — path + query params only (confirms no regression)
  class NoHeaderAction < ScenarioAction
    get "/scenarios/header-parameters/plain/:id" do
      plain_text "ok"
    end
  end
end
