struct PetCatResponse
  include JSON::Serializable
  property id : Int64
  property name : String
  property purr_volume : Int32
end

struct PetDogResponse
  include JSON::Serializable
  property id : Int64
  property name : String
  property bark_loudness : Int32
end

struct PetBaseResponse
  include JSON::Serializable
  property id : Int64
  property name : String
end

struct PetExtensionResponse
  include JSON::Serializable
  property species : String
  property traits : Array(String)
end

module PolymorphicResponseScenario
  # oneOf: union of two concrete response shapes
  @[LuckySwagger::Response(200, one_of: [PetCatResponse, PetDogResponse])]
  class PolyPetShow < ScenarioAction
    get "/scenarios/polymorphic-response/poly-pets/:id" do
      plain_text "ok"
    end
  end

  # anyOf: looser union — response may match one or more schemas
  @[LuckySwagger::Response(200, any_of: [PetCatResponse, PetDogResponse])]
  class AnyPetShow < ScenarioAction
    get "/scenarios/polymorphic-response/any-pets/:id" do
      plain_text "ok"
    end
  end

  # allOf: composition — response satisfies all listed schemas
  @[LuckySwagger::Response(200, all_of: [PetBaseResponse, PetExtensionResponse])]
  class ComposedPetShow < ScenarioAction
    get "/scenarios/polymorphic-response/composed-pets/:id" do
      plain_text "ok"
    end
  end
end
