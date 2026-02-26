module LuckySwagger
  class OpenApiGenerator
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
                 result
               end

      result = {
        openapi:    "3.0.0",
        info:       {
          title:       LuckySwagger.settings.title,
          description: LuckySwagger.settings.description,
          version:     LuckySwagger.settings.version,
        },
        paths:      paths,
        components: build_components,
      }

      # Add servers array if configured
      if LuckySwagger.settings.servers.any?
        result = result.merge({servers: LuckySwagger.settings.servers})
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
      components = {schemas: collect_schemas}

      # Add security schemes if configured
      if LuckySwagger.settings.security_schemes.any?
        components = components.merge({securitySchemes: LuckySwagger.settings.security_schemes})
      end

      components
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
            {% end %}
            {% rb_ann = action.annotation(LuckySwagger::RequestBody) %}
            {% if rb_ann && rb_ann[:schema] %}
              {% schema_type = rb_ann[:schema].resolve %}
              {% schema_name = schema_type.name(generic_args: false).split("::").last %}
              {{ schema_name }} => SchemaIntrospector.openapi_schema({{ schema_type }}),
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
        tags:        extract_tags(action_class, action_path),
        summary:     extract_summary(action_class, action_path),
        description: extract_description(action_class),
        parameters:  generate_params_description(route),
      }

      # Add deprecated flag if set
      if is_deprecated?(action_class)
        route_spec = route_spec.merge({deprecated: true})
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

      # If no explicit security annotation, use default security from config
      if LuckySwagger.settings.default_security.any?
        return LuckySwagger.settings.default_security
      end

      nil
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

      # Skip generic prefixes like "Api", "Actions", etc.
      filtered_path = path_without_action.reject { |part| ["Api", "Actions", "V1", "V2"].includes?(part) }

      if filtered_path.size >= 2
        # Multiple levels: join with " > " (e.g., "Frontend > Users")
        [filtered_path.join(" > ")]
      elsif filtered_path.size == 1
        # Single level: just use it
        [filtered_path[0]]
      else
        # Fallback if everything was filtered out
        ["default"]
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

      action_path.join(' ')
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

    # --- Parameter generation with enum support ---

    private def self.generate_params_description(route : Tuple(String, String, Lucky::Action.class))
      action_class = route[2]

      path_params = route[0].scan(/:\w+/).map do |param|
        {
          name:     param[0].delete(':'),
          in:       "path",
          required: true,
          schema:   {type: "string"},
        }
      end

      query_params = route[2].query_param_declarations.map do |param|
        name = param.split(" : ").first
        type = param.split(" : ").last

        {
          name:     name,
          in:       "query",
          required: !type.includes?("::Nil"),
          schema:   {
            type: infer_param_type(type),
          },
        }
      end

      # Attach enum values to matching query params
      enriched_query_params = query_params.map do |qp|
        enum_values = get_enum_values(action_class, qp[:name])
        if enum_values
          qp.merge({enum: enum_values})
        else
          qp
        end
      end

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
            {% request_body_ann = action.annotation(LuckySwagger::RequestBody) %}
            {% if request_body_ann && request_body_ann[:schema] %}
              {% schema_type = request_body_ann[:schema].resolve %}
              {% schema_name = schema_type.name(generic_args: false).split("::").last %}
              return {
                required: true,
                content:  {
                  "application/json" => {
                    schema: {"$ref" => "#/components/schemas/{{ schema_name.id }}"},
                  },
                },
              }
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
                          },
                        },
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
                        },
                      },
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
            content:     {
              "application/json" => {
                schema: {type: "object"},
              },
            },
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

    private def self.infer_param_type(crystal_type : String) : String
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
  end
end
