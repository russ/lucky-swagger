module PathParamTypesScenario
  # :id → integer int64 (by name)
  class ShowById < ScenarioAction
    get "/scenarios/path-param-types/things/:id" do
      plain_text "ok"
    end
  end

  # :item_id → integer int64 (by _id suffix)
  class ShowByItemId < ScenarioAction
    get "/scenarios/path-param-types/items/:item_id" do
      plain_text "ok"
    end
  end

  # :token → string (default, no format)
  class ShowByToken < ScenarioAction
    get "/scenarios/path-param-types/tokens/:token" do
      plain_text "ok"
    end
  end

  # Multiple params in one route
  class ShowNested < ScenarioAction
    get "/scenarios/path-param-types/orgs/:org_id/members/:member_id" do
      plain_text "ok"
    end
  end
end
