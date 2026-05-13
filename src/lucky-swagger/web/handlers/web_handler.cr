module LuckySwagger
  module Handlers
    class WebHandler
      include HTTP::Handler

      property swagger_files : Array(String)
      property swagger_urls : Array(NamedTuple(name: String, url: String))

      @static_handler : HTTP::StaticFileHandler?

      # live: true — generate spec on every request (dev mode, no disk file needed).
      # live: false (default) — serve pre-written YAML files from @folder.
      def initialize(
        @swagger_url : String = "/swagger",
        @folder : String = "./swagger",
        @live : Bool = false
      )
        if @live
          @swagger_files = [] of String
          @swagger_urls = [{name: "live", url: "#{@swagger_url}/live.yaml"}]
          @static_handler = nil
        else
          @static_handler = ::HTTP::StaticFileHandler.new(@folder, fallthrough: false)
          @swagger_files = Dir.exists?(@folder) ? Dir.entries(@folder).select { |f| f.includes?(".yaml") } : [] of String
          @swagger_urls = @swagger_files.map { |file| {name: file.split('.').first, url: "/#{file}"} }
        end
      end

      def call(context : HTTP::Server::Context)
        if context.request.path == @swagger_url
          context.response.status_code = 200
          context.response.headers["Content-Type"] = "text/html"
          ECR.embed("#{__DIR__}/../views/index.html.ecr", context.response)
        elsif @live && context.request.path == "#{@swagger_url}/live.yaml"
          context.response.status_code = 200
          context.response.headers["Content-Type"] = "application/yaml"
          context.response.print(OpenApiGenerator.generate_yaml)
        elsif !@live && context.request.path.includes?(".yaml") && File.exists?(@folder + context.request.path)
          if handler = @static_handler
            handler.call(context)
          else
            call_next(context)
          end
        else
          call_next(context)
        end
      end
    end
  end
end
