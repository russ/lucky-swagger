module LuckySwagger
  class LintSpec < LuckyTask::Task
    summary "Lint the generated OpenAPI spec using Spectral"

    arg :filename, "Path to the spec file to lint (default: ./swagger/api.yaml)",
      shortcut: "-f",
      optional: true

    switch :generate, "Regenerate the spec before linting",
      shortcut: "-g"

    def call
      spec_file = filename || "./swagger/api.yaml"

      if generate
        yaml_content = OpenApiGenerator.generate_yaml
        Dir.mkdir_p(Path[spec_file].dirname)
        File.write(spec_file, yaml_content)
        output.puts "Spec regenerated at #{spec_file}"
      end

      unless File.exists?(spec_file)
        output.puts "Spec file not found: #{spec_file}"
        output.puts "Run with --generate (-g) to generate it first, or run lucky_swagger.generate_open_api"
        return
      end

      spectral = find_spectral
      if spectral.nil?
        output.puts "Spectral not found. Install it with:"
        output.puts "  npm install -g @stoplight/spectral-cli"
        output.puts "  # or use npx: npx @stoplight/spectral-cli lint #{spec_file}"
        return
      end

      output.puts "Running Spectral lint on #{spec_file}..."
      result = Process.run(spectral, ["lint", "--format", "text", spec_file],
        output: output, error: output)

      if result.success?
        output.puts "Spectral lint passed."
      else
        output.puts "Spectral lint found issues (exit #{result.exit_code})."
      end
    end

    private def find_spectral : String?
      ["spectral", "npx @stoplight/spectral-cli"].each do |cmd|
        parts = cmd.split(' ', 2)
        check = Process.run("which", [parts[0]], output: Process::Redirect::Close, error: Process::Redirect::Close)
        return cmd if check.success?
      end
      nil
    end
  end
end
