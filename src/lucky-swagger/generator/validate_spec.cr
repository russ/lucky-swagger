module LuckySwagger
  module SpecValidator
    def self.validate(yaml_string : String) : Array(String)
      errors = [] of String
      parsed = YAML.parse(yaml_string)

      check_required_structure(parsed, errors)
      check_refs(parsed, errors) if errors.empty?

      errors
    end

    def self.validate!(yaml_string : String) : Nil
      errors = validate(yaml_string)
      raise "OpenAPI spec validation failed:\n  #{errors.join("\n  ")}" unless errors.empty?
    end

    private def self.check_required_structure(parsed : YAML::Any, errors : Array(String))
      version = parsed["openapi"]?.try(&.as_s?)
      if version.nil? || !version.starts_with?("3.")
        errors << "openapi: must be a 3.x version string (got #{version.inspect})"
      end

      info = parsed["info"]?
      if info.nil?
        errors << "info: object is required"
      else
        errors << "info.title: must be a non-empty string" if info["title"]?.try(&.as_s?).nil?
        errors << "info.version: must be a non-empty string" if info["version"]?.try(&.as_s?).nil?
      end

      errors << "paths: object is required" if parsed["paths"]?.nil?
    end

    private def self.check_refs(parsed : YAML::Any, errors : Array(String))
      schema_keys = parsed.dig?("components", "schemas").try(&.as_h?.try(&.keys.map(&.as_s))) || [] of String
      known = Set(String).new(schema_keys)

      collect_refs(parsed).each do |ref|
        next unless ref.starts_with?("#/components/schemas/")
        name = ref.lchop("#/components/schemas/")
        errors << "$ref '#{ref}' points to a schema '#{name}' not found in components/schemas" unless known.includes?(name)
      end
    end

    private def self.collect_refs(node : YAML::Any) : Array(String)
      refs = [] of String
      case raw = node.raw
      when Hash
        raw.each do |k, v|
          if k.as_s? == "$ref"
            refs << v.as_s if v.as_s?
          else
            refs.concat(collect_refs(v))
          end
        end
      when Array
        raw.each { |v| refs.concat(collect_refs(v)) }
      end
      refs
    end
  end
end
