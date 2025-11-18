require "../../../spec_helper"
require "file_utils"
require "http"

describe LuckySwagger::Handlers::WebHandler do
  describe "initialization" do
    it "initializes with default swagger URL and folder" do
      # Create test swagger directory
      FileUtils.rm_rf("./swagger")
      Dir.mkdir_p("./swagger")
      File.write("./swagger/api.yaml", "openapi: 3.0.0")

      begin
        handler = LuckySwagger::Handlers::WebHandler.new

        handler.swagger_files.should contain("api.yaml")
        handler.swagger_urls.size.should be > 0
      ensure
        FileUtils.rm_rf("./swagger")
      end
    end

    it "initializes with custom swagger URL and folder" do
      # Create test directory
      FileUtils.rm_rf("./spec/tmp/docs")
      Dir.mkdir_p("./spec/tmp/docs")
      File.write("./spec/tmp/docs/v1.yaml", "openapi: 3.0.0")

      begin
        handler = LuckySwagger::Handlers::WebHandler.new(
          swagger_url: "/custom/swagger",
          folder: "./spec/tmp/docs"
        )

        handler.swagger_files.should contain("v1.yaml")
      ensure
        FileUtils.rm_rf("./spec/tmp")
      end
    end

    it "discovers multiple YAML files in swagger folder" do
      # Create test directory with multiple files
      FileUtils.rm_rf("./spec/tmp/swagger")
      Dir.mkdir_p("./spec/tmp/swagger")
      File.write("./spec/tmp/swagger/api_v1.yaml", "openapi: 3.0.0")
      File.write("./spec/tmp/swagger/api_v2.yaml", "openapi: 3.0.0")
      File.write("./spec/tmp/swagger/readme.txt", "not yaml")

      begin
        handler = LuckySwagger::Handlers::WebHandler.new(folder: "./spec/tmp/swagger")

        handler.swagger_files.size.should eq(2)
        handler.swagger_files.should contain("api_v1.yaml")
        handler.swagger_files.should contain("api_v2.yaml")
        handler.swagger_files.should_not contain("readme.txt")
      ensure
        FileUtils.rm_rf("./spec/tmp")
      end
    end
  end

  describe "#call" do
    it "serves SwaggerUI HTML at configured path" do
      FileUtils.rm_rf("./spec/tmp/swagger")
      Dir.mkdir_p("./spec/tmp/swagger")
      File.write("./spec/tmp/swagger/api.yaml", "openapi: 3.0.0")

      begin
        handler = LuckySwagger::Handlers::WebHandler.new(
          swagger_url: "/docs",
          folder: "./spec/tmp/swagger"
        )

        request = HTTP::Request.new("GET", "/docs")
        response = HTTP::Server::Response.new(IO::Memory.new)
        context = HTTP::Server::Context.new(request, response)

        handler.call(context)

        context.response.status_code.should eq(200)
        context.response.headers["Content-Type"].should eq("text/html")
      ensure
        FileUtils.rm_rf("./spec/tmp")
      end
    end

    it "serves YAML files from swagger folder" do
      FileUtils.rm_rf("./spec/tmp/swagger")
      Dir.mkdir_p("./spec/tmp/swagger")
      File.write("./spec/tmp/swagger/api.yaml", "openapi: 3.0.0\ninfo:\n  title: Test API")

      begin
        handler = LuckySwagger::Handlers::WebHandler.new(folder: "./spec/tmp/swagger")

        request = HTTP::Request.new("GET", "/api.yaml")
        response = HTTP::Server::Response.new(IO::Memory.new)
        context = HTTP::Server::Context.new(request, response)

        handler.call(context)

        context.response.status_code.should eq(200)
      ensure
        FileUtils.rm_rf("./spec/tmp")
      end
    end

    it "calls next handler for non-swagger paths" do
      FileUtils.rm_rf("./spec/tmp/swagger")
      Dir.mkdir_p("./spec/tmp/swagger")
      File.write("./spec/tmp/swagger/api.yaml", "openapi: 3.0.0")

      begin
        handler = LuckySwagger::Handlers::WebHandler.new(folder: "./spec/tmp/swagger")

        # Create a mock next handler
        next_called = false
        handler.next = HTTP::Handler::HandlerProc.new do |ctx|
          next_called = true
        end

        request = HTTP::Request.new("GET", "/some/other/path")
        response = HTTP::Server::Response.new(IO::Memory.new)
        context = HTTP::Server::Context.new(request, response)

        handler.call(context)

        next_called.should be_true
      ensure
        FileUtils.rm_rf("./spec/tmp")
      end
    end

    it "returns 404 for non-existent YAML files" do
      FileUtils.rm_rf("./spec/tmp/swagger")
      Dir.mkdir_p("./spec/tmp/swagger")
      File.write("./spec/tmp/swagger/api.yaml", "openapi: 3.0.0")

      begin
        handler = LuckySwagger::Handlers::WebHandler.new(folder: "./spec/tmp/swagger")

        # Create a mock next handler
        next_called = false
        handler.next = HTTP::Handler::HandlerProc.new do |ctx|
          next_called = true
        end

        request = HTTP::Request.new("GET", "/nonexistent.yaml")
        response = HTTP::Server::Response.new(IO::Memory.new)
        context = HTTP::Server::Context.new(request, response)

        handler.call(context)

        # Should call next handler since file doesn't exist
        next_called.should be_true
      ensure
        FileUtils.rm_rf("./spec/tmp")
      end
    end
  end

  describe "swagger_urls generation" do
    it "generates URL mappings from YAML files" do
      FileUtils.rm_rf("./spec/tmp/swagger")
      Dir.mkdir_p("./spec/tmp/swagger")
      File.write("./spec/tmp/swagger/api_v1.yaml", "openapi: 3.0.0")
      File.write("./spec/tmp/swagger/api_v2.yaml", "openapi: 3.0.0")

      begin
        handler = LuckySwagger::Handlers::WebHandler.new(folder: "./spec/tmp/swagger")

        handler.swagger_urls.size.should eq(2)
        handler.swagger_urls.any? { |u| u[:name] == "api_v1" }.should be_true
        handler.swagger_urls.any? { |u| u[:name] == "api_v2" }.should be_true
        handler.swagger_urls.any? { |u| u[:url] == "/api_v1.yaml" }.should be_true
        handler.swagger_urls.any? { |u| u[:url] == "/api_v2.yaml" }.should be_true
      ensure
        FileUtils.rm_rf("./spec/tmp")
      end
    end
  end
end
