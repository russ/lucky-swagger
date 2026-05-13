module DeprecationInferenceScenario
  @[LuckySwagger::Endpoint(deprecated: true)]
  class Deprecated < ScenarioAction
    get "/scenarios/deprecation-inference/deprecated" do
      plain_text "ok"
    end
  end

  class Active < ScenarioAction
    get "/scenarios/deprecation-inference/active" do
      plain_text "ok"
    end
  end
end
