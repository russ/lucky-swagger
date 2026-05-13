module AuthMixinInferenceScenario
  module FakeAuth
    module RequireBearer
    end

    module RequireApiKey
    end
  end

  class BearerOnly < ScenarioAction
    include FakeAuth::RequireBearer

    get "/scenarios/auth-mixin-inference/bearer-only" do
      plain_text "ok"
    end
  end

  class Public < ScenarioAction
    get "/scenarios/auth-mixin-inference/public" do
      plain_text "ok"
    end
  end

  @[LuckySwagger::Endpoint(security: "none")]
  class OverrideNone < ScenarioAction
    include FakeAuth::RequireBearer

    get "/scenarios/auth-mixin-inference/override-none" do
      plain_text "ok"
    end
  end

  class BothMixins < ScenarioAction
    include FakeAuth::RequireBearer
    include FakeAuth::RequireApiKey

    get "/scenarios/auth-mixin-inference/both" do
      plain_text "ok"
    end
  end
end
