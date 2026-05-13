module OAuth2FlowsScenario
  class TokenAction < ScenarioAction
    post "/scenarios/oauth2-flows/token" do
      plain_text "ok"
    end
  end

  class MeAction < ScenarioAction
    get "/scenarios/oauth2-flows/me" do
      plain_text "ok"
    end
  end
end
