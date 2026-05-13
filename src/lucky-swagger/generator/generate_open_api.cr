module LuckySwagger
  class GenerateOpenApi < LuckyTask::Task
    summary "Generate OpenAPI documentation for API routes"

    arg :filename, "Output file path",
      shortcut: "-f",
      optional: true

    arg :format, "Output format: yaml (default) or json",
      shortcut: "-F",
      optional: true

    switch :validate, "Validate the generated spec for structural errors",
      shortcut: "-v"

    def call
      fmt = format || "yaml"
      default_ext = fmt == "json" ? "json" : "yaml"
      file = filename || "./swagger/api.#{default_ext}"

      yaml_content = OpenApiGenerator.generate_yaml

      if validate?
        errors = SpecValidator.validate(yaml_content)
        if errors.any?
          output.puts "Spec validation errors:"
          errors.each { |e| output.puts "  - #{e}" }
          return
        end
        output.puts "Spec validation passed."
      end

      content = fmt == "json" ? YAML.parse(yaml_content).to_json : yaml_content
      Dir.mkdir_p(Path[file].dirname)
      File.write(file, content)

      output.puts "OpenAPI spec written to #{file}"
    end
  end
end
