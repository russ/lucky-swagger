module CookieParametersScenario
  # Cookie-only params
  @[LuckySwagger::CookieParam(name: "session_id", type: String, required: true, description: "Session token")]
  @[LuckySwagger::CookieParam(name: "theme", type: String, required: false)]
  class CookieAction < ScenarioAction
    get "/scenarios/cookie-parameters/items/:id" do
      plain_text "ok"
    end
  end

  # Both header and cookie params on the same action
  @[LuckySwagger::HeaderParam(name: "X-Request-ID", type: String, required: false)]
  @[LuckySwagger::CookieParam(name: "session_id", type: String, required: true)]
  class MixedParamAction < ScenarioAction
    get "/scenarios/cookie-parameters/mixed/:id" do
      plain_text "ok"
    end
  end
end
