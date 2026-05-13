module RouteFilterRegexScenario
  class Included < ScenarioAction
    get "/scenarios/route-filter-regex/included" do
      plain_text "ok"
    end
  end

  class AlsoIncluded < ScenarioAction
    get "/scenarios/route-filter-regex/also" do
      plain_text "ok"
    end
  end

  class NotIncluded < ScenarioAction
    get "/elsewhere/route-filter-regex/skipped" do
      plain_text "ok"
    end
  end
end
