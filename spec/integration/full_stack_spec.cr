require "../spec_helper"
require "file_utils"
require "http/client"

# Full integration test with a mock Lucky application
describe "LuckySwagger Full Integration" do
  describe "complete workflow" do
    it "generates OpenAPI spec and serves it via WebHandler" do
      # Setup: Create swagger directory
      FileUtils.rm_rf("./spec/tmp/integration")
      Dir.mkdir_p("./spec/tmp/integration")

      begin
        # Step 1: Generate OpenAPI YAML file
        output_file = "./spec/tmp/integration/api.yaml"
        File.open(output_file, "w") do |file|
          YAML.dump(LuckySwagger::OpenApiGenerator.generate_open_api, file)
        end

        File.exists?(output_file).should be_true

        # Step 2: Verify generated content
        content = File.read(output_file)
        parsed = YAML.parse(content)

        parsed["openapi"].as_s.should eq("3.0.0")
        parsed["info"]["title"].as_s.should eq("API")
        parsed["paths"].should_not be_nil

        # Step 3: Initialize WebHandler with the generated file
        handler = LuckySwagger::Handlers::WebHandler.new(
          swagger_url: "/api-docs",
          folder: "./spec/tmp/integration"
        )

        handler.swagger_files.should contain("api.yaml")
        handler.swagger_urls.size.should be > 0

        # Step 4: Test serving SwaggerUI
        request = HTTP::Request.new("GET", "/api-docs")
        response = HTTP::Server::Response.new(IO::Memory.new)
        context = HTTP::Server::Context.new(request, response)

        handler.call(context)

        context.response.status_code.should eq(200)
        context.response.headers["Content-Type"].should eq("text/html")

        # Step 5: Test serving YAML file
        yaml_request = HTTP::Request.new("GET", "/api.yaml")
        yaml_response = HTTP::Server::Response.new(IO::Memory.new)
        yaml_context = HTTP::Server::Context.new(yaml_request, yaml_response)

        handler.call(yaml_context)

        yaml_context.response.status_code.should eq(200)
      ensure
        FileUtils.rm_rf("./spec/tmp/integration")
      end
    end

    it "handles multiple API versions" do
      FileUtils.rm_rf("./spec/tmp/multi-version")
      Dir.mkdir_p("./spec/tmp/multi-version")

      begin
        # Generate multiple API specs
        v1_spec = LuckySwagger::OpenApiGenerator.generate_open_api.merge({
          info: {
            title:       "API V1",
            description: "API version 1",
            version:     "1.0.0",
          },
        })

        v2_spec = LuckySwagger::OpenApiGenerator.generate_open_api.merge({
          info: {
            title:       "API V2",
            description: "API version 2",
            version:     "2.0.0",
          },
        })

        File.open("./spec/tmp/multi-version/v1.yaml", "w") do |file|
          YAML.dump(v1_spec, file)
        end

        File.open("./spec/tmp/multi-version/v2.yaml", "w") do |file|
          YAML.dump(v2_spec, file)
        end

        # Initialize handler
        handler = LuckySwagger::Handlers::WebHandler.new(
          swagger_url: "/docs",
          folder: "./spec/tmp/multi-version"
        )

        handler.swagger_files.size.should eq(2)
        handler.swagger_urls.size.should eq(2)

        # Should have both versions
        handler.swagger_urls.any? { |u| u[:name] == "v1" }.should be_true
        handler.swagger_urls.any? { |u| u[:name] == "v2" }.should be_true
      ensure
        FileUtils.rm_rf("./spec/tmp/multi-version")
      end
    end
  end

  describe "API route introspection" do
    it "correctly introspects registered Lucky routes" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      paths = result[:paths]

      # Should only include API routes (those with 'api' in path)
      if paths
        paths.as(Hash).keys.each do |path|
          path.to_s.should contain("api")
        end
      end
    end

    it "converts route parameters correctly" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      paths = result[:paths]

      # Should convert :param to {param} in route paths
      if paths
        paths.as(Hash).keys.each do |path|
          path_str = path.to_s
          # Path should not contain Lucky-style route params like :id
          # But should contain OpenAPI-style params like {id}
          if path_str.includes?("{")
            # If it has OpenAPI params, make sure it doesn't also have Lucky-style
            path_str.should_not match(/\/:\w+/)
          end
        end
      end
    end

    it "generates proper HTTP method specifications" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      # The generated spec should have HTTP methods as keys if routes exist
      result_str = result.to_s.downcase

      # If there are paths, they should have HTTP methods
      if result[:paths]
        http_methods = ["get", "post", "put", "patch", "delete"]
        has_method = http_methods.any? { |method| result_str.includes?(method) }
        has_method.should be_true
      else
        # No routes registered is also valid
        result[:paths].should be_nil
      end
    end
  end

  describe "components/schemas in YAML output" do
    it "includes components/schemas section in generated YAML" do
      FileUtils.rm_rf("./spec/tmp/schemas")
      Dir.mkdir_p("./spec/tmp/schemas")

      begin
        output_file = "./spec/tmp/schemas/api.yaml"
        File.open(output_file, "w") do |file|
          YAML.dump(LuckySwagger::OpenApiGenerator.generate_open_api, file)
        end

        content = File.read(output_file)
        parsed = YAML.parse(content)

        # Should have components/schemas
        parsed["components"].should_not be_nil
        parsed["components"]["schemas"].should_not be_nil

        # Built-in schemas
        parsed["components"]["schemas"]["Pagination"].should_not be_nil
        parsed["components"]["schemas"]["Error"].should_not be_nil
      ensure
        FileUtils.rm_rf("./spec/tmp/schemas")
      end
    end

    it "includes $ref references in generated YAML" do
      FileUtils.rm_rf("./spec/tmp/refs")
      Dir.mkdir_p("./spec/tmp/refs")

      begin
        output_file = "./spec/tmp/refs/api.yaml"
        File.open(output_file, "w") do |file|
          YAML.dump(LuckySwagger::OpenApiGenerator.generate_open_api, file)
        end

        content = File.read(output_file)
        # Annotated actions should produce $ref entries
        content.should contain("#/components/schemas/")
      ensure
        FileUtils.rm_rf("./spec/tmp/refs")
      end
    end

    it "includes enum arrays in generated YAML" do
      FileUtils.rm_rf("./spec/tmp/enums")
      Dir.mkdir_p("./spec/tmp/enums")

      begin
        output_file = "./spec/tmp/enums/api.yaml"
        File.open(output_file, "w") do |file|
          YAML.dump(LuckySwagger::OpenApiGenerator.generate_open_api, file)
        end

        content = File.read(output_file)
        # Feed::Index has swagger_enum with filter values
        content.should contain("all")
        content.should contain("following")
      ensure
        FileUtils.rm_rf("./spec/tmp/enums")
      end
    end
  end

  describe "error handling" do
    it "handles empty swagger directory gracefully" do
      FileUtils.rm_rf("./spec/tmp/empty")
      Dir.mkdir_p("./spec/tmp/empty")

      begin
        handler = LuckySwagger::Handlers::WebHandler.new(folder: "./spec/tmp/empty")

        handler.swagger_files.should be_empty
        handler.swagger_urls.should be_empty

        # Should still serve SwaggerUI even with no files
        request = HTTP::Request.new("GET", "/swagger")
        response = HTTP::Server::Response.new(IO::Memory.new)
        context = HTTP::Server::Context.new(request, response)

        handler.call(context)

        context.response.status_code.should eq(200)
      ensure
        FileUtils.rm_rf("./spec/tmp/empty")
      end
    end

    it "passes through requests for non-YAML files" do
      FileUtils.rm_rf("./spec/tmp/mixed")
      Dir.mkdir_p("./spec/tmp/mixed")
      File.write("./spec/tmp/mixed/api.yaml", "openapi: 3.0.0")
      File.write("./spec/tmp/mixed/readme.md", "# README")

      begin
        handler = LuckySwagger::Handlers::WebHandler.new(folder: "./spec/tmp/mixed")

        next_called = false
        handler.next = HTTP::Handler::HandlerProc.new do |ctx|
          next_called = true
        end

        # Request for .md file should pass through
        request = HTTP::Request.new("GET", "/readme.md")
        response = HTTP::Server::Response.new(IO::Memory.new)
        context = HTTP::Server::Context.new(request, response)

        handler.call(context)

        next_called.should be_true
      ensure
        FileUtils.rm_rf("./spec/tmp/mixed")
      end
    end
  end

  describe "response structure" do
    it "includes all required OpenAPI 3.0 fields" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      # Required top-level fields
      result.has_key?(:openapi).should be_true
      result.has_key?(:info).should be_true
      result.has_key?(:paths).should be_true
      result.has_key?(:components).should be_true

      # Info object required fields
      result[:info][:title].should eq("API")
      result[:info][:version].should eq("1.0.0")
    end

    it "includes responses for each route" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      paths = result[:paths]
      if paths && !paths.as(Hash).empty?
        first_path = paths.as(Hash).values.first
        if first_path.is_a?(Hash)
          first_method = first_path.values.first
          first_method.to_s.should contain("responses")
          # POST endpoints typically return 201 or 200
          first_method_str = first_method.to_s
          (first_method_str.includes?("200") || first_method_str.includes?("201")).should be_true
        end
      end
    end

    it "includes tags for route categorization" do
      result = LuckySwagger::OpenApiGenerator.generate_open_api

      # Tags are only present if there are routes
      if result[:paths]
        result_str = result.to_s
        result_str.should contain("tags")
      else
        # No routes is valid for this test
        result[:paths].should be_nil
      end
    end
  end
end
