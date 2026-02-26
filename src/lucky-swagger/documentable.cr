module LuckySwagger
  # Include in actions and serializers to enable OpenAPI documentation generation.
  #
  # For actions:
  #   abstract class ApiAction < Lucky::Action
  #     include LuckySwagger::Documentable
  #   end
  #
  # For serializers:
  #   struct UserSerializer < BaseSerializer
  #     include LuckySwagger::Documentable
  #
  #     swagger_fields do
  #       property id : Int64
  #       property name : String
  #       property email : String?
  #     end
  #   end
  module Documentable
    # Declares typed fields for OpenAPI schema generation.
    # Creates a nested `SwaggerSchema` struct with JSON::Serializable
    # that the generator introspects at compile time.
    #
    # Usage:
    #   swagger_fields do
    #     property id : Int64
    #     property text : String
    #     property comments_count : Int32
    #   end
    macro swagger_fields(&block)
      struct SwaggerSchema
        include JSON::Serializable

        {{ block.body }}
      end
    end

    # Declares allowed enum values for a query parameter.
    # The generator reads these at compile time to populate the
    # OpenAPI `enum` constraint on the matching parameter.
    #
    # Usage:
    #   param filter : String = "all"
    #   swagger_enum filter, ["all", "following", "subscribed", "myposts"]
    macro swagger_enum(param_name, values)
      private def self.__swagger_enum__{{param_name.id}}
        {{values}}
      end
    end
  end
end
