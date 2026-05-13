module LuckySwagger
  class OpenApiGenerator
    def self.generate_yaml : String
      YAML.dump(generate_open_api)
    end

    def self.generate_json : String
      YAML.parse(YAML.dump(generate_open_api)).to_json
    end

    def self.generate_open_api
      routes = filter_routes(Lucky.router.list_routes)
      paths = if routes.any?
                result = generate_route_description(routes.first)
                routes.each_with_index do |route, i|
                  next if i == 0
                  new_entry = generate_route_description(route)
                  new_entry.each do |path, methods|
                    if result.has_key?(path)
                      result[path] = result[path].merge(methods)
                    else
                      result[path] = methods
                    end
                  end
                end
                result.to_a.sort_by { |path, _| path }.to_h
              end

      # Build result with optional servers and security
      has_servers = LuckySwagger.settings.servers.any?
      has_security = LuckySwagger.settings.default_security.any?
      info = build_info

      if has_servers && has_security
        {
          openapi:    "3.0.0",
          info:       info,
          servers:    LuckySwagger.settings.servers,
          paths:      paths,
          components: build_components,
          security:   LuckySwagger.settings.default_security,
        }
      elsif has_servers
        {
          openapi:    "3.0.0",
          info:       info,
          servers:    LuckySwagger.settings.servers,
          paths:      paths,
          components: build_components,
        }
      elsif has_security
        {
          openapi:    "3.0.0",
          info:       info,
          paths:      paths,
          components: build_components,
          security:   LuckySwagger.settings.default_security,
        }
      else
        {
          openapi:    "3.0.0",
          info:       info,
          paths:      paths,
          components: build_components,
        }
      end
    end

    private def self.build_info
      base = {
        title:       LuckySwagger.settings.title,
        description: LuckySwagger.settings.description,
        version:     LuckySwagger.settings.version,
      }
      result = base

      if tos = LuckySwagger.settings.terms_of_service
        result = result.merge({termsOfService: tos})
      end

      if contact = LuckySwagger.settings.contact
        result = result.merge({contact: contact})
      end

      if license = LuckySwagger.settings.license
        result = result.merge({license: license})
      end

      result
    end

    # Filter routes based on configuration settings
    private def self.filter_routes(all_routes)
      all_routes.select do |route|
        method = route[1].downcase
        path = route[0].to_s

        # Always exclude HEAD requests
        next false if method == "head"

        # Apply include_routes filter
        case LuckySwagger.settings.include_routes
        when :all
          true
        when :api_only
          # Matches paths containing the literal string "api" (e.g. /api/v1/users).
          # For /v1/-prefixed apps use include_routes: /^\/v1\// instead.
          path.includes?("api")
        when Regex
          path.match(LuckySwagger.settings.include_routes.as(Regex)) != nil
        else
          true
        end
      end
    end

    # Build components section with schemas and security schemes
    private def self.build_components
      simple = LuckySwagger.settings.security_schemes
      oauth2 = LuckySwagger.settings.oauth2_schemes
      if simple.any? || oauth2.any?
        all_schemes = {} of String => (Hash(String, String) | OAuth2Scheme)
        simple.each { |k, v| all_schemes[k] = v }
        oauth2.each { |k, v| all_schemes[k] = v }
        {
          schemas:         collect_schemas,
          securitySchemes: all_schemes,
        }
      else
        {
          schemas: collect_schemas,
        }
      end
    end

    # Build entire schemas hash as a single compile-time literal.
    # Duplicate keys (from multiple actions referencing the same serializer) are harmless.
    private def self.collect_schemas
      {% begin %}
        {
          "Pagination" => {
            type:       "object",
            required:   ["total_items", "total_pages", "per_page"],
            properties: {
              "next_page"     => {type: "string", nullable: true},
              "previous_page" => {type: "string", nullable: true},
              "total_items"   => {type: "integer", format: "int32"},
              "total_pages"   => {type: "integer", format: "int32"},
              "per_page"      => {type: "integer", format: "int32"},
            },
          },
          "Error" => {
            type:       "object",
            required:   ["message"],
            properties: {
              "message" => {type: "string"},
              "param"   => {type: "string", nullable: true},
              "details" => {type: "string", nullable: true},
            },
          },
          {% for action in Lucky::Action.all_subclasses %}
            {% for ann in action.annotations(LuckySwagger::Response) %}
              {% if ann[:serializer] %}
                {% serializer = ann[:serializer].resolve %}
                {% if serializer.has_constant?("SwaggerSchema") %}
                  {% schema_name = serializer.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") %}
                  {{ schema_name }} => SchemaIntrospector.openapi_schema({{ serializer }}::SwaggerSchema),
                {% end %}
              {% elsif ann[:schema] %}
                {% schema_type = ann[:schema].resolve %}
                {% schema_name = schema_type.name(generic_args: false).split("::").last.gsub(/Schema$/, "") %}
                {% unless schema_name == "Pagination" || schema_name == "Error" %}
                  {{ schema_name }} => SchemaIntrospector.openapi_schema({{ schema_type }}),
                {% end %}
              {% end %}
              {% if ann[:one_of] %}
                {% for type_node in ann[:one_of] %}
                  {% resolved = type_node.resolve %}
                  {% if resolved.has_constant?("SwaggerSchema") %}
                    {% schema_name = resolved.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") %}
                    {{ schema_name }} => SchemaIntrospector.openapi_schema({{ resolved }}::SwaggerSchema),
                  {% else %}
                    {% schema_name = resolved.name(generic_args: false).split("::").last.gsub(/Schema$/, "") %}
                    {{ schema_name }} => SchemaIntrospector.openapi_schema({{ resolved }}),
                  {% end %}
                {% end %}
              {% end %}
              {% if ann[:any_of] %}
                {% for type_node in ann[:any_of] %}
                  {% resolved = type_node.resolve %}
                  {% if resolved.has_constant?("SwaggerSchema") %}
                    {% schema_name = resolved.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") %}
                    {{ schema_name }} => SchemaIntrospector.openapi_schema({{ resolved }}::SwaggerSchema),
                  {% else %}
                    {% schema_name = resolved.name(generic_args: false).split("::").last.gsub(/Schema$/, "") %}
                    {{ schema_name }} => SchemaIntrospector.openapi_schema({{ resolved }}),
                  {% end %}
                {% end %}
              {% end %}
              {% if ann[:all_of] %}
                {% for type_node in ann[:all_of] %}
                  {% resolved = type_node.resolve %}
                  {% if resolved.has_constant?("SwaggerSchema") %}
                    {% schema_name = resolved.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") %}
                    {{ schema_name }} => SchemaIntrospector.openapi_schema({{ resolved }}::SwaggerSchema),
                  {% else %}
                    {% schema_name = resolved.name(generic_args: false).split("::").last.gsub(/Schema$/, "") %}
                    {{ schema_name }} => SchemaIntrospector.openapi_schema({{ resolved }}),
                  {% end %}
                {% end %}
              {% end %}
            {% end %}
            {% rb_ann = action.annotation(LuckySwagger::RequestBody) %}
            {% if rb_ann && rb_ann[:schema] %}
              {% schema_type = rb_ann[:schema].resolve %}
              {% schema_name = schema_type.name(generic_args: false).split("::").last.gsub(/Schema$/, "") %}
              {{ schema_name }} => SchemaIntrospector.openapi_schema({{ schema_type }}),
            {% end %}

            # IR-2: Operation annotation — register the operation's SwaggerSchema
            {% op_ann = action.annotation(LuckySwagger::Operation) %}
            {% if op_ann && op_ann[0] %}
              {% op_type = op_ann[0].resolve %}
              {% if op_type.has_constant?("SwaggerSchema") %}
                {% schema_name = op_type.name(generic_args: false).split("::").last %}
                {{ schema_name }} => SchemaIntrospector.openapi_schema({{ op_type }}::SwaggerSchema),
              {% end %}
            {% end %}

            # IR-2: Convention discovery — Save<SingularResource>.
            # Try top-level first (::SaveUser), then namespace-relative (Api::Frontend::SaveUser).
            {% action_parts = action.name(generic_args: false).split("::") %}
            {% action_basename = action_parts.last %}
            {% if (action_basename == "Create" || action_basename == "Update") && action_parts.size >= 2 %}
              {% resource_ns = action_parts[-2] %}
              {% if resource_ns.ends_with?("ies") %}
                {% singular = resource_ns[0..-4] + "y" %}
              {% elsif resource_ns.ends_with?("ses") || resource_ns.ends_with?("xes") || resource_ns.ends_with?("zes") || resource_ns.ends_with?("ches") || resource_ns.ends_with?("shes") %}
                {% singular = resource_ns[0..-3] %}
              {% elsif resource_ns.ends_with?("s") %}
                {% singular = resource_ns[0..-2] %}
              {% else %}
                {% singular = resource_ns %}
              {% end %}
              {% candidate = parse_type("::Save" + singular).resolve? %}
              {% unless candidate && candidate.has_constant?("SwaggerSchema") %}
                {% ns_prefix = action_parts[0..-3].join("::") %}
                {% candidate = ns_prefix.size > 0 ? parse_type(ns_prefix + "::Save" + singular).resolve? : nil %}
              {% end %}
              {% if candidate && candidate.has_constant?("SwaggerSchema") %}
                {% schema_name = candidate.name(generic_args: false).split("::").last %}
                {{ schema_name }} => SchemaIntrospector.openapi_schema({{ candidate }}::SwaggerSchema),
              {% end %}
            {% end %}

            # IR-3 & IR-4: Convention-based response serializer for Show/Create/Update/Index
            # without a Response annotation. Register the inferred serializer's
            # schema so the $ref resolves.
            {% response_anns = action.annotations(LuckySwagger::Response) %}
            {% if response_anns.size == 0 %}
              {% if (action_basename == "Show" || action_basename == "Create" || action_basename == "Update" || action_basename == "Index") && action_parts.size >= 2 %}
                {% resource_ns = action_parts[-2] %}
                {% if resource_ns.ends_with?("ies") %}
                {% singular = resource_ns[0..-4] + "y" %}
              {% elsif resource_ns.ends_with?("ses") || resource_ns.ends_with?("xes") || resource_ns.ends_with?("zes") || resource_ns.ends_with?("ches") || resource_ns.ends_with?("shes") %}
                {% singular = resource_ns[0..-3] %}
              {% elsif resource_ns.ends_with?("s") %}
                {% singular = resource_ns[0..-2] %}
              {% else %}
                {% singular = resource_ns %}
              {% end %}
                {% serializer_candidate = parse_type("::" + singular + "Serializer").resolve? %}
                {% if serializer_candidate && serializer_candidate.has_constant?("SwaggerSchema") %}
                  {% schema_name = serializer_candidate.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") %}
                  {{ schema_name }} => SchemaIntrospector.openapi_schema({{ serializer_candidate }}::SwaggerSchema),
                {% end %}
              {% end %}
            {% end %}
          {% end %}
        }
      {% end %}
    end

    private def self.generate_route_description(route : Tuple(String, String, Lucky::Action.class))
      action_class = route[2]
      action_path = action_class.name.split("::")
      method = route[1].downcase

      route_spec = {
        operationId: extract_operation_id(action_class, action_path),
        tags:        extract_tags(action_class, action_path),
        summary:     extract_summary(action_class, action_path),
        parameters:  generate_params_description(route),
      }

      # Only emit description when non-empty to avoid `description: ""` on every unannotated op
      desc = extract_description(action_class)
      unless desc.empty?
        route_spec = route_spec.merge({description: desc})
      end

      # Add deprecated flag if set
      if is_deprecated?(action_class)
        route_spec = route_spec.merge({deprecated: true})
      end

      # Add externalDocs if declared via @[Endpoint(external_docs: {url: ..., description: ...})]
      external_docs = extract_external_docs(action_class)
      if external_docs
        route_spec = route_spec.merge({externalDocs: external_docs})
      end

      # Add per-operation servers override via @[Endpoint(servers: [{url: ..., description: ...}])]
      op_servers = extract_operation_servers(action_class)
      if op_servers
        route_spec = route_spec.merge({servers: op_servers})
      end

      # Add security requirements
      security = extract_security(action_class)
      if security
        route_spec = route_spec.merge({security: security})
      end

      if ["post", "put", "patch"].includes?(method)
        request_body = extract_request_body(action_class)
        if request_body
          route_spec = route_spec.merge({requestBody: request_body})
        else
          route_spec = route_spec.merge({requestBody: generate_default_request_body(route)})
        end
      end

      responses = extract_responses(action_class, method)
      route_spec = route_spec.merge({responses: responses})

      {
        format_route_url(route[0]) => {
          method => route_spec,
        },
      }
    end

    # --- Tag, summary, description, security, deprecation extraction via Endpoint annotation ---

    private def self.is_deprecated?(action_class) : Bool
      {% begin %}
        {% for action in Lucky::Action.all_subclasses %}
          if action_class == {{ action }}
            {% endpoint = action.annotation(LuckySwagger::Endpoint) %}
            {% if endpoint && endpoint[:deprecated] %}
              return {{ endpoint[:deprecated] }}
            {% end %}
          end
        {% end %}
      {% end %}

      false
    end

    private def self.extract_security(action_class)
      {% begin %}
        {% for action in Lucky::Action.all_subclasses %}
          if action_class == {{ action }}
            {% endpoint = action.annotation(LuckySwagger::Endpoint) %}
            {% if endpoint && endpoint[:security] %}
              {% security_value = endpoint[:security] %}
              {% if security_value == "none" %}
                # Explicitly no security - return empty array to override defaults
                return [] of Hash(String, Array(String))
              {% else %}
                # Specific security scheme name
                return [{ {{ security_value.stringify }} => [] of String }]
              {% end %}
            {% end %}
          end
        {% end %}
      {% end %}

      # IR-1: Infer security from registered auth mixins (ancestors).
      # All matched schemes are AND-combined into a single requirement.
      mixin_map = LuckySwagger.settings.auth_mixin_map
      if mixin_map.any?
        matched = {} of String => Array(String)
        action_ancestor_names(action_class).each do |name|
          if scheme = mixin_map[name]?
            matched[scheme] = [] of String
          end
        end
        return [matched] if matched.any?
      end

      # If no explicit security annotation, use default security from config
      if LuckySwagger.settings.default_security.any?
        return LuckySwagger.settings.default_security
      end

      nil
    end

    # Returns the list of ancestor class/module names for a given action,
    # computed at compile time, queried at runtime against the auth_mixin_map.
    private def self.action_ancestor_names(action_class) : Array(String)
      {% begin %}
        {% for action in Lucky::Action.all_subclasses %}
          if action_class == {{ action }}
            return [
              {% for anc in action.ancestors %}
                {{ anc.name(generic_args: false).stringify }},
              {% end %}
            ] of String
          end
        {% end %}
      {% end %}

      [] of String
    end

    private def self.extract_tags(action_class, action_path)
      {% begin %}
        {% for action in Lucky::Action.all_subclasses %}
          if action_class == {{ action }}
            {% endpoint = action.annotation(LuckySwagger::Endpoint) %}
            {% if endpoint && endpoint[:tags] %}
              return {{ endpoint[:tags] }}
            {% end %}
          end
        {% end %}
      {% end %}

      # Auto-generate tags from namespace hierarchy
      # Example: Api::Frontend::Users::Index -> ["Frontend > Users"] or ["Users"]
      # Example: Api::Users::Index -> ["Users"]
      generate_tags_from_namespace(action_path)
    end

    private def self.generate_tags_from_namespace(action_path : Array(String))
      # Remove the action name (e.g., "Index", "Show", "Create")
      path_without_action = action_path[0..-2]

      # IR-8: configurable stripping, separator, and default tag
      strip_prefixes = LuckySwagger.settings.tag_strip_prefixes
      filtered_path = path_without_action.reject { |part| strip_prefixes.includes?(part) }

      if filtered_path.size >= 2
        [filtered_path.join(LuckySwagger.settings.tag_separator)]
      elsif filtered_path.size == 1
        [filtered_path[0]]
      else
        [LuckySwagger.settings.default_tag]
      end
    end

    private def self.extract_summary(action_class, action_path)
      {% begin %}
        {% for action in Lucky::Action.all_subclasses %}
          if action_class == {{ action }}
            {% endpoint = action.annotation(LuckySwagger::Endpoint) %}
            {% if endpoint && endpoint[:summary] %}
              return {{ endpoint[:summary] }}
            {% end %}
          end
        {% end %}
      {% end %}

      generate_summary_from_path(action_path)
    end

    private def self.generate_summary_from_path(action_path : Array(String)) : String
      action_name = action_path.last
      resource = action_path.size >= 2 ? action_path[-2] : ""

      case action_name
      when "Index"   then "List #{resource.downcase}"
      when "Show"    then "Get #{resource.downcase.chomp("s")}"
      when "Create"  then "Create #{resource.downcase.chomp("s")}"
      when "Update"  then "Update #{resource.downcase.chomp("s")}"
      when "Destroy" then "Delete #{resource.downcase.chomp("s")}"
      when "New"     then "New #{resource.downcase.chomp("s")} form"
      when "Edit"    then "Edit #{resource.downcase.chomp("s")} form"
      else
        # Non-standard action: humanize name and prepend resource context
        human_action = action_name.gsub(/([A-Z])/) { " #{$~[1]}" }.strip.downcase
        resource.empty? ? human_action : "#{human_action} #{resource.downcase}"
      end
    end

    private def self.extract_description(action_class)
      {% begin %}
        {% for action in Lucky::Action.all_subclasses %}
          if action_class == {{ action }}
            {% endpoint = action.annotation(LuckySwagger::Endpoint) %}
            {% if endpoint && endpoint[:description] %}
              return {{ endpoint[:description] }}
            {% end %}
          end
        {% end %}
      {% end %}

      ""
    end

    private def self.extract_operation_servers(action_class)
      {% begin %}
        {% for action in Lucky::Action.all_subclasses %}
          if action_class == {{ action }}
            {% endpoint = action.annotation(LuckySwagger::Endpoint) %}
            {% if endpoint && endpoint[:servers] %}
              return [
                {% for srv in endpoint[:servers] %}
                  {% if srv[:description] %}
                    {url: {{ srv[:url] }}, description: {{ srv[:description] }}},
                  {% else %}
                    {url: {{ srv[:url] }}},
                  {% end %}
                {% end %}
              ]
            {% end %}
          end
        {% end %}
      {% end %}

      nil
    end

    private def self.extract_external_docs(action_class)
      {% begin %}
        {% for action in Lucky::Action.all_subclasses %}
          if action_class == {{ action }}
            {% endpoint = action.annotation(LuckySwagger::Endpoint) %}
            {% if endpoint && endpoint[:external_docs] %}
              {% ext = endpoint[:external_docs] %}
              {% if ext[:description] %}
                return {url: {{ ext[:url] }}, description: {{ ext[:description] }}}
              {% else %}
                return {url: {{ ext[:url] }}}
              {% end %}
            {% end %}
          end
        {% end %}
      {% end %}

      nil
    end

    # Returns the operationId for an action. Priority:
    # 1. @[Endpoint(operation_id: "...")] explicit annotation
    # 2. Auto-generated from action class name parts, formatted per operation_id_style config
    private def self.extract_operation_id(action_class, action_path : Array(String)) : String
      {% begin %}
        {% for action in Lucky::Action.all_subclasses %}
          if action_class == {{ action }}
            {% endpoint = action.annotation(LuckySwagger::Endpoint) %}
            {% if endpoint && endpoint[:operation_id] %}
              return {{ endpoint[:operation_id] }}
            {% end %}
          end
        {% end %}
      {% end %}

      generate_operation_id(action_path)
    end

    private def self.generate_operation_id(action_path : Array(String)) : String
      strip_prefixes = LuckySwagger.settings.tag_strip_prefixes
      parts = action_path.reject { |p| strip_prefixes.includes?(p) }
      parts = action_path if parts.empty?

      if LuckySwagger.settings.operation_id_style == "snake_case"
        parts.map(&.downcase).join("_")
      else
        # camelCase: first part fully lowercase, each subsequent part capitalised
        first = parts[0].downcase
        rest = parts[1..].map { |p| p[0..0].upcase + p[1..] }
        ([first] + rest).join
      end
    end

    # --- Parameter generation with enum support ---

    private def self.generate_params_description(route : Tuple(String, String, Lucky::Action.class))
      action_class = route[2]

      path_params = route[0].scan(/:\w+/).map do |param|
        param_name = param[0].delete(':')
        {
          name:     param_name,
          in:       "path",
          required: true,
          schema:   infer_path_param_schema(param_name),
        }
      end

      query_params = route[2].query_param_declarations.map do |param|
        name = param.split(" : ").first
        type = param.split(" : ").last

        {
          name:     name,
          in:       "query",
          required: false, # Query params are always optional (can be omitted from request)
          schema:   {
            type: infer_param_type(type),
          },
        }
      end

      # Attach enum values to matching query params (nested inside schema)
      enriched_query_params = query_params.map do |qp|
        enum_values = get_enum_values(action_class, qp[:name])
        if enum_values
          # Merge enum into the schema, not at the parameter level
          {
            name:     qp[:name],
            in:       qp[:in],
            required: qp[:required],
            schema:   {
              type: qp[:schema][:type],
              enum: enum_values,
            },
          }
        else
          qp
        end
      end

      {% begin %}
        {% for action in Lucky::Action.all_subclasses %}
          if action_class == {{ action }}
            {% header_anns = action.annotations(LuckySwagger::HeaderParam) %}
            {% cookie_anns = action.annotations(LuckySwagger::CookieParam) %}
            {% if header_anns.size > 0 || cookie_anns.size > 0 %}
              return path_params + enriched_query_params + [
                {% for ann in header_anns %}
                  {% if ann[:type] %}
                    {% resolved_type = ann[:type].resolve %}
                    {% if resolved_type == String %}{% openapi_type = "string" %}
                    {% elsif resolved_type == Int32 || resolved_type == Int64 %}{% openapi_type = "integer" %}
                    {% elsif resolved_type == Float32 || resolved_type == Float64 %}{% openapi_type = "number" %}
                    {% elsif resolved_type == Bool %}{% openapi_type = "boolean" %}
                    {% else %}{% openapi_type = "string" %}{% end %}
                  {% else %}{% openapi_type = "string" %}{% end %}
                  {% required_val = ann[:required] != nil ? ann[:required] : false %}
                  {% if ann[:description] %}
                    {name: {{ ann[:name] }}, in: "header", required: {{ required_val }}, description: {{ ann[:description] }}, schema: {type: {{ openapi_type }}}},
                  {% else %}
                    {name: {{ ann[:name] }}, in: "header", required: {{ required_val }}, schema: {type: {{ openapi_type }}}},
                  {% end %}
                {% end %}
                {% for ann in cookie_anns %}
                  {% if ann[:type] %}
                    {% resolved_type = ann[:type].resolve %}
                    {% if resolved_type == String %}{% openapi_type = "string" %}
                    {% elsif resolved_type == Int32 || resolved_type == Int64 %}{% openapi_type = "integer" %}
                    {% elsif resolved_type == Float32 || resolved_type == Float64 %}{% openapi_type = "number" %}
                    {% elsif resolved_type == Bool %}{% openapi_type = "boolean" %}
                    {% else %}{% openapi_type = "string" %}{% end %}
                  {% else %}{% openapi_type = "string" %}{% end %}
                  {% required_val = ann[:required] != nil ? ann[:required] : false %}
                  {% if ann[:description] %}
                    {name: {{ ann[:name] }}, in: "cookie", required: {{ required_val }}, description: {{ ann[:description] }}, schema: {type: {{ openapi_type }}}},
                  {% else %}
                    {name: {{ ann[:name] }}, in: "cookie", required: {{ required_val }}, schema: {type: {{ openapi_type }}}},
                  {% end %}
                {% end %}
              ]
            {% end %}
          end
        {% end %}
      {% end %}

      path_params + enriched_query_params
    end

    # Look up enum values defined via swagger_enum for a given action + param name
    private def self.get_enum_values(action_class, param_name : String) : Array(String)?
      {% begin %}
        {% for action in Lucky::Action.all_subclasses %}
          if action_class == {{ action }}
            {% for m in action.class.methods %}
              {% if m.name.starts_with?("__swagger_enum__") %}
                {% extracted_name = m.name.gsub(/^__swagger_enum__/, "") %}
                if param_name == {{ extracted_name.stringify }}
                  return {{ m.body }}
                end
              {% end %}
            {% end %}
          end
        {% end %}
      {% end %}

      nil
    end

    # --- Request body extraction ---

    private def self.extract_request_body(action_class)
      {% begin %}
        {% for action in Lucky::Action.all_subclasses %}
          if action_class == {{ action }}
            # Priority 1: Explicit @[RequestBody(schema: ...)] or @[RequestBody(multipart: {...})]
            {% request_body_ann = action.annotation(LuckySwagger::RequestBody) %}
            {% if request_body_ann && request_body_ann[:schema] %}
              {% schema_type = request_body_ann[:schema].resolve %}
              {% schema_name = schema_type.name(generic_args: false).split("::").last.gsub(/Schema$/, "") %}
              return {
                required: true,
                content:  {
                  "application/json" => {
                    schema: {"$ref" => "#/components/schemas/{{ schema_name.id }}"},
                  },
                },
              }
            {% elsif request_body_ann && request_body_ann[:multipart] %}
              {% required_fields = request_body_ann[:required] %}
              return {
                required: true,
                content:  {
                  "multipart/form-data" => {
                    schema: {
                      type:       "object",
                      {% if required_fields && required_fields.size > 0 %}
                      required:   {{ required_fields.map(&.stringify) }},
                      {% end %}
                      properties: {
                        {% for field_name, field_type in request_body_ann[:multipart] %}
                          {% resolved = field_type.resolve %}
                          {% if resolved == ::File %}
                            {{ field_name.stringify }} => {type: "string", format: "binary"},
                          {% elsif resolved == String %}
                            {{ field_name.stringify }} => {type: "string"},
                          {% elsif resolved == Int32 || resolved == Int64 %}
                            {{ field_name.stringify }} => {type: "integer"},
                          {% elsif resolved == Float32 || resolved == Float64 %}
                            {{ field_name.stringify }} => {type: "number"},
                          {% elsif resolved == Bool %}
                            {{ field_name.stringify }} => {type: "boolean"},
                          {% else %}
                            {{ field_name.stringify }} => {type: "string"},
                          {% end %}
                        {% end %}
                      },
                    },
                  },
                },
              }
            {% end %}

            # Priority 2: @[LuckySwagger::Operation(SaveX)] — operation must declare swagger_fields
            {% op_ann = action.annotation(LuckySwagger::Operation) %}
            {% if op_ann && op_ann[0] %}
              {% op_type = op_ann[0].resolve %}
              {% if op_type.has_constant?("SwaggerSchema") %}
                {% schema_name = op_type.name(generic_args: false).split("::").last %}
                return {
                  required: true,
                  content:  {
                    "application/json" => {
                      schema: {"$ref" => "#/components/schemas/{{ schema_name.id }}"},
                    },
                  },
                }
              {% end %}
            {% end %}

            # Priority 3: Convention — Foo::Bar::Create => Save<SingularBar>
            # Try top-level (::SaveBar) then namespace-relative (Foo::SaveBar).
            {% action_parts = action.name(generic_args: false).split("::") %}
            {% action_basename = action_parts.last %}
            {% if (action_basename == "Create" || action_basename == "Update") && action_parts.size >= 2 %}
              {% resource_ns = action_parts[-2] %}
              {% if resource_ns.ends_with?("ies") %}
                {% singular = resource_ns[0..-4] + "y" %}
              {% elsif resource_ns.ends_with?("ses") || resource_ns.ends_with?("xes") || resource_ns.ends_with?("zes") || resource_ns.ends_with?("ches") || resource_ns.ends_with?("shes") %}
                {% singular = resource_ns[0..-3] %}
              {% elsif resource_ns.ends_with?("s") %}
                {% singular = resource_ns[0..-2] %}
              {% else %}
                {% singular = resource_ns %}
              {% end %}
              {% candidate = parse_type("::Save" + singular).resolve? %}
              {% unless candidate && candidate.has_constant?("SwaggerSchema") %}
                {% ns_prefix = action_parts[0..-3].join("::") %}
                {% candidate = ns_prefix.size > 0 ? parse_type(ns_prefix + "::Save" + singular).resolve? : nil %}
              {% end %}
              {% if candidate && candidate.has_constant?("SwaggerSchema") %}
                {% schema_name = candidate.name(generic_args: false).split("::").last %}
                return {
                  required: true,
                  content:  {
                    "application/json" => {
                      schema: {"$ref" => "#/components/schemas/{{ schema_name.id }}"},
                    },
                  },
                }
              {% end %}
            {% end %}
          end
        {% end %}
      {% end %}

      nil
    end

    private def self.generate_default_request_body(route : Tuple(String, String, Lucky::Action.class))
      resource_name = route[2].name.split("::").size > 1 ? route[2].name.split("::")[-2].downcase : "item"

      {
        required: true,
        content:  {
          "application/json" => {
            schema: {
              type:       "object",
              properties: {
                resource_name => {
                  type:        "object",
                  description: "#{resource_name.capitalize} data",
                },
              },
            },
          },
        },
      }
    end

    # --- Response extraction with $ref and collection support ---
    #
    # For each annotated action, generate a complete return with a hash literal
    # at compile time. This avoids the need for an intermediate runtime hash
    # (which Crystal can't type as Hash(String, NamedTuple)).
    #
    # For POST/PUT/PATCH actions without an explicit 422, we generate an
    # additional code path that includes the auto-422 error response.

    private def self.extract_responses(action_class, method : String)
      {% begin %}
        {% for action in Lucky::Action.all_subclasses %}
          {% anns = action.annotations(LuckySwagger::Response) %}

          # IR-4: Convention-based inference for Index actions. Looks for
          # ::<SingularResource>Serializer and emits a paginated collection
          # response (items + pagination wrapper).
          {% if anns.size == 0 %}
            {% action_parts = action.name(generic_args: false).split("::") %}
            {% action_basename = action_parts.last %}
            {% if action_basename == "Index" && action_parts.size >= 2 %}
              {% resource_ns = action_parts[-2] %}
              {% if resource_ns.ends_with?("ies") %}
                {% singular = resource_ns[0..-4] + "y" %}
              {% elsif resource_ns.ends_with?("ses") || resource_ns.ends_with?("xes") || resource_ns.ends_with?("zes") || resource_ns.ends_with?("ches") || resource_ns.ends_with?("shes") %}
                {% singular = resource_ns[0..-3] %}
              {% elsif resource_ns.ends_with?("s") %}
                {% singular = resource_ns[0..-2] %}
              {% else %}
                {% singular = resource_ns %}
              {% end %}
              {% serializer_candidate = parse_type("::" + singular + "Serializer").resolve? %}
              {% if serializer_candidate && serializer_candidate.has_constant?("SwaggerSchema") %}
                {% schema_name = serializer_candidate.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") %}
                if action_class == {{ action }}
                  return {
                    "200" => {
                      description: "Success",
                      content:     {
                        "application/json" => {
                          schema: {
                            type:       "object",
                            properties: {
                              "items" => {
                                type:  "array",
                                items: {"$ref" => "#/components/schemas/{{ schema_name.id }}"},
                              },
                              "pagination" => {"$ref" => "#/components/schemas/Pagination"},
                            },
                          },
                        },
                      },
                    },
                  }
                end
              {% end %}
            {% end %}
          {% end %}

          # IR-3: Convention-based inference for Show/Create/Update actions without
          # an explicit Response annotation. Looks for ::<SingularResource>Serializer
          # at top level. Show => 200, Create => 201, Update => 200. Auto-422 added
          # for write methods.
          {% if anns.size == 0 %}
            {% action_parts = action.name(generic_args: false).split("::") %}
            {% action_basename = action_parts.last %}
            {% if (action_basename == "Show" || action_basename == "Create" || action_basename == "Update") && action_parts.size >= 2 %}
              {% resource_ns = action_parts[-2] %}
              {% if resource_ns.ends_with?("ies") %}
                {% singular = resource_ns[0..-4] + "y" %}
              {% elsif resource_ns.ends_with?("ses") || resource_ns.ends_with?("xes") || resource_ns.ends_with?("zes") || resource_ns.ends_with?("ches") || resource_ns.ends_with?("shes") %}
                {% singular = resource_ns[0..-3] %}
              {% elsif resource_ns.ends_with?("s") %}
                {% singular = resource_ns[0..-2] %}
              {% else %}
                {% singular = resource_ns %}
              {% end %}
              {% serializer_candidate = parse_type("::" + singular + "Serializer").resolve? %}
              {% if serializer_candidate && serializer_candidate.has_constant?("SwaggerSchema") %}
                {% schema_name = serializer_candidate.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") %}
                {% inferred_status = action_basename == "Create" ? "201" : "200" %}

                if action_class == {{ action }} && ["post", "put", "patch"].includes?(method)
                  return {
                    {{ inferred_status }} => {
                      description: "Success",
                      content:     {
                        "application/json" => {
                          schema: {"$ref" => "#/components/schemas/{{ schema_name.id }}"},
                        },
                      },
                    },
                    "422" => {
                      description: "Validation errors",
                      content:     {
                        "application/json" => {
                          schema: {"$ref" => "#/components/schemas/Error"},
                        },
                      },
                    },
                  }
                end

                if action_class == {{ action }}
                  return {
                    {{ inferred_status }} => {
                      description: "Success",
                      content:     {
                        "application/json" => {
                          schema: {"$ref" => "#/components/schemas/{{ schema_name.id }}"},
                        },
                      },
                    },
                  }
                end
              {% end %}
            {% end %}
          {% end %}

          {% if anns.size > 0 %}
            {% has_422 = anns.any? { |a|
                 code = a.args[0] ? a.args[0].stringify : (a[:status] ? a[:status].stringify : "200")
                 code == "422"
               } %}

            # Generate the write-method path (with auto-422) if needed
            {% unless has_422 %}
              if action_class == {{ action }} && ["post", "put", "patch"].includes?(method)
                return {
                  {% for ann in anns %}
                    {% status_code = ann.args[0] ? ann.args[0].stringify : (ann[:status] ? ann[:status].stringify : "200") %}
                    {% description = ann[:description] %}
                    {% if ann[:serializer] %}
                      {% serializer = ann[:serializer].resolve %}
                      {% schema_name = serializer.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") %}
                      {% if ann[:collection] %}
                        {{ status_code }} => {
                          description: {{ description || "Success" }},
                          content: {
                            "application/json" => {
                              schema: {
                                type: "object",
                                properties: {
                                  "items" => {
                                    type: "array",
                                    items: {"$ref" => "#/components/schemas/{{ schema_name.id }}"},
                                  },
                                  "pagination" => {"$ref" => "#/components/schemas/Pagination"},
                                },
                              },
                            },
                          },
                        },
                      {% else %}
                        {{ status_code }} => {
                          description: {{ description || "Success" }},
                          content: {
                            "application/json" => {
                              schema: {"$ref" => "#/components/schemas/{{ schema_name.id }}"},
                              {% if ann[:example] %}example: {{ ann[:example] }},{% end %}
                            },
                          },
                        },
                      {% end %}
                    {% elsif ann[:schema] %}
                      {% schema_type = ann[:schema].resolve %}
                      {% schema_name = schema_type.name(generic_args: false).split("::").last.gsub(/Schema$/, "") %}
                      {{ status_code }} => {
                        description: {{ description || "Success" }},
                        content: {
                          "application/json" => {
                            schema: {"$ref" => "#/components/schemas/{{ schema_name.id }}"},
                            {% if ann[:example] %}example: {{ ann[:example] }},{% end %}
                          },
                        },
                      },
                    {% elsif ann[:content_type] %}
                      {{ status_code }} => {
                        description: {{ description || "Success" }},
                        content: {
                          {{ ann[:content_type] }} => {
                            schema: {type: "string"},
                            {% if ann[:example] %}example: {{ ann[:example] }},{% end %}
                          },
                        },
                      },
                    {% elsif ann[:one_of] %}
                      {{ status_code }} => {
                        description: {{ description || "Success" }},
                        content: {
                          "application/json" => {
                            schema: {
                              "oneOf" => [
                                {% for type_node in ann[:one_of] %}
                                  {% resolved = type_node.resolve %}
                                  {% name = resolved.has_constant?("SwaggerSchema") ? resolved.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") : resolved.name(generic_args: false).split("::").last.gsub(/Schema$/, "") %}
                                  {"$ref" => "#/components/schemas/{{ name.id }}"},
                                {% end %}
                              ],
                              {% if ann[:discriminator] %}
                              "discriminator" => {"propertyName" => {{ ann[:discriminator] }}},
                              {% end %}
                            },
                          },
                        },
                      },
                    {% elsif ann[:any_of] %}
                      {{ status_code }} => {
                        description: {{ description || "Success" }},
                        content: {
                          "application/json" => {
                            schema: {
                              "anyOf" => [
                                {% for type_node in ann[:any_of] %}
                                  {% resolved = type_node.resolve %}
                                  {% name = resolved.has_constant?("SwaggerSchema") ? resolved.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") : resolved.name(generic_args: false).split("::").last.gsub(/Schema$/, "") %}
                                  {"$ref" => "#/components/schemas/{{ name.id }}"},
                                {% end %}
                              ],
                              {% if ann[:discriminator] %}
                              "discriminator" => {"propertyName" => {{ ann[:discriminator] }}},
                              {% end %}
                            },
                          },
                        },
                      },
                    {% elsif ann[:all_of] %}
                      {{ status_code }} => {
                        description: {{ description || "Success" }},
                        content: {
                          "application/json" => {
                            schema: {
                              "allOf" => [
                                {% for type_node in ann[:all_of] %}
                                  {% resolved = type_node.resolve %}
                                  {% name = resolved.has_constant?("SwaggerSchema") ? resolved.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") : resolved.name(generic_args: false).split("::").last.gsub(/Schema$/, "") %}
                                  {"$ref" => "#/components/schemas/{{ name.id }}"},
                                {% end %}
                              ],
                            },
                          },
                        },
                      },
                    {% else %}
                      {% if status_code == "204" %}
                        {{ status_code }} => {
                          description: {{ description || "No Content" }},
                        },
                      {% else %}
                        {{ status_code }} => {
                          description: {{ description || "Success" }},
                          content: {
                            "application/json" => {
                              schema: {type: "object"},
                            },
                          },
                        },
                      {% end %}
                    {% end %}
                  {% end %}
                  "422" => {
                    description: "Validation errors",
                    content: {
                      "application/json" => {
                        schema: {"$ref" => "#/components/schemas/Error"},
                      },
                    },
                  },
                }
              end
            {% end %}

            # Standard path (no auto-422, or 422 was explicitly declared)
            if action_class == {{ action }}
              return {
                {% for ann in anns %}
                  {% status_code = ann.args[0] ? ann.args[0].stringify : (ann[:status] ? ann[:status].stringify : "200") %}
                  {% description = ann[:description] %}
                  {% if ann[:serializer] %}
                    {% serializer = ann[:serializer].resolve %}
                    {% schema_name = serializer.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") %}
                    {% if ann[:collection] %}
                      {{ status_code }} => {
                        description: {{ description || "Success" }},
                        content: {
                          "application/json" => {
                            schema: {
                              type: "object",
                              properties: {
                                "items" => {
                                  type: "array",
                                  items: {"$ref" => "#/components/schemas/{{ schema_name.id }}"},
                                },
                                "pagination" => {"$ref" => "#/components/schemas/Pagination"},
                              },
                            },
                          },
                        },
                      },
                    {% else %}
                      {{ status_code }} => {
                        description: {{ description || "Success" }},
                        content: {
                          "application/json" => {
                            schema: {"$ref" => "#/components/schemas/{{ schema_name.id }}"},
                            {% if ann[:example] %}example: {{ ann[:example] }},{% end %}
                          },
                        },
                      },
                    {% end %}
                  {% elsif ann[:schema] %}
                    {% schema_type = ann[:schema].resolve %}
                    {% schema_name = schema_type.name(generic_args: false).split("::").last.gsub(/Schema$/, "") %}
                    {{ status_code }} => {
                      description: {{ description || "Success" }},
                      content: {
                        "application/json" => {
                          schema: {"$ref" => "#/components/schemas/{{ schema_name.id }}"},
                          {% if ann[:example] %}example: {{ ann[:example] }},{% end %}
                        },
                      },
                    },
                  {% elsif ann[:content_type] %}
                    {{ status_code }} => {
                      description: {{ description || "Success" }},
                      content: {
                        {{ ann[:content_type] }} => {
                          schema: {type: "string"},
                          {% if ann[:example] %}example: {{ ann[:example] }},{% end %}
                        },
                      },
                    },
                  {% elsif ann[:one_of] %}
                    {{ status_code }} => {
                      description: {{ description || "Success" }},
                      content: {
                        "application/json" => {
                          schema: {
                            "oneOf" => [
                              {% for type_node in ann[:one_of] %}
                                {% resolved = type_node.resolve %}
                                {% name = resolved.has_constant?("SwaggerSchema") ? resolved.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") : resolved.name(generic_args: false).split("::").last.gsub(/Schema$/, "") %}
                                {"$ref" => "#/components/schemas/{{ name.id }}"},
                              {% end %}
                            ],
                            {% if ann[:discriminator] %}
                            "discriminator" => {"propertyName" => {{ ann[:discriminator] }}},
                            {% end %}
                          },
                        },
                      },
                    },
                  {% elsif ann[:any_of] %}
                    {{ status_code }} => {
                      description: {{ description || "Success" }},
                      content: {
                        "application/json" => {
                          schema: {
                            "anyOf" => [
                              {% for type_node in ann[:any_of] %}
                                {% resolved = type_node.resolve %}
                                {% name = resolved.has_constant?("SwaggerSchema") ? resolved.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") : resolved.name(generic_args: false).split("::").last.gsub(/Schema$/, "") %}
                                {"$ref" => "#/components/schemas/{{ name.id }}"},
                              {% end %}
                            ],
                            {% if ann[:discriminator] %}
                            "discriminator" => {"propertyName" => {{ ann[:discriminator] }}},
                            {% end %}
                          },
                        },
                      },
                    },
                  {% elsif ann[:all_of] %}
                    {{ status_code }} => {
                      description: {{ description || "Success" }},
                      content: {
                        "application/json" => {
                          schema: {
                            "allOf" => [
                              {% for type_node in ann[:all_of] %}
                                {% resolved = type_node.resolve %}
                                {% name = resolved.has_constant?("SwaggerSchema") ? resolved.name(generic_args: false).split("::").last.gsub(/Serializer$/, "") : resolved.name(generic_args: false).split("::").last.gsub(/Schema$/, "") %}
                                {"$ref" => "#/components/schemas/{{ name.id }}"},
                              {% end %}
                            ],
                          },
                        },
                      },
                    },
                  {% else %}
                    {% if status_code == "204" %}
                      {{ status_code }} => {
                        description: {{ description || "No Content" }},
                      },
                    {% else %}
                      {{ status_code }} => {
                        description: {{ description || "Success" }},
                        content: {
                          "application/json" => {
                            schema: {type: "object"},
                          },
                        },
                      },
                    {% end %}
                  {% end %}
                {% end %}
              }
            end
          {% end %}
        {% end %}
      {% end %}

      # Fallback: no Response annotations on this action
      generate_default_responses(method)
    end

    private def self.generate_default_responses(method : String)
      case method
      when "post"
        {
          "201" => {
            description: "Created successfully",
            content:     {
              "application/json" => {
                schema: {type: "object"},
              },
            },
          },
          "422" => {
            description: "Validation errors",
            content:     {
              "application/json" => {
                schema: {"$ref" => "#/components/schemas/Error"},
              },
            },
          },
        }
      when "put", "patch"
        {
          "200" => {
            description: "Updated successfully",
            content:     {
              "application/json" => {
                schema: {type: "object"},
              },
            },
          },
          "422" => {
            description: "Validation errors",
            content:     {
              "application/json" => {
                schema: {"$ref" => "#/components/schemas/Error"},
              },
            },
          },
        }
      when "delete"
        {
          "204" => {
            description: "Deleted successfully",
          },
        }
      else
        {
          "200" => {
            description: "Success",
            content:     {
              "application/json" => {
                schema: {type: "object"},
              },
            },
          },
        }
      end
    end

    # Infer schema for a path parameter by name.
    # Consults format_map first (keyed by param name), then applies heuristics:
    # - params ending in _id → integer int64 (override with format_map if UUID-based)
    private def self.infer_path_param_schema(param_name : String)
      format_map = LuckySwagger.settings.format_map
      if entry = format_map[param_name]?
        return {type: entry[:type], format: entry[:format]}
      end
      if param_name.ends_with?("_id") || param_name == "id"
        return {type: "integer", format: "int64"}
      end
      {type: "string"}
    end

    private def self.infer_param_type(crystal_type : String) : String
      # Check user-configured format_map first (keyed by unqualified type name)
      short = crystal_type.split("::").last.gsub("?", "")
      if entry = LuckySwagger.settings.format_map[short]?
        return entry[:type]
      end

      case crystal_type
      when .includes?("String") then "string"
      when .includes?("Int")    then "integer"
      when .includes?("Float")  then "number"
      when .includes?("Bool")   then "boolean"
      else                           "string"
      end
    end

    private def self.format_route_url(url : String) : String
      url.gsub(/:\w+/) { |param| "{#{param.delete(':')}}" }
    end

    # Singularize a namespace part for convention-based lookups (SaveX, XSerializer).
    # Checks inflect_overrides first, then falls back to naive trailing-s strip.
    private def self.singularize(word : String) : String
      overrides = LuckySwagger.settings.inflect_overrides
      return overrides[word] if overrides.has_key?(word)
      word.ends_with?("s") ? word[0..-2] : word
    end
  end
end
