module LuckySwagger
  class SchemaIntrospector
    # Extract OpenAPI schema from a Crystal struct/class with JSON::Serializable.
    # All property type resolution is inlined to avoid passing resolved TypeNodes
    # across macro boundaries (which breaks for union types).
    macro openapi_schema(type)
      {% begin %}
        {% resolved_type = type.resolve %}
        {
          type: "object",
          required: [
            {% for ivar in resolved_type.instance_vars %}
              {% unless ivar.type.resolve.nilable? %}
                {{ ivar.name.stringify }},
              {% end %}
            {% end %}
          ] of String,
          properties: {
            {% for ivar in resolved_type.instance_vars %}
              {% ivar_type = ivar.type.resolve %}
              {% fm = ivar.annotation(LuckySwagger::FieldMeta) %}

              # Extract all FieldMeta keys upfront (nil when absent).
              # Use .nil? checks for minimum/maximum/default so zero, false, and "" emit correctly.
              {% if fm && fm[:example] %}{% ex = fm[:example] %}{% else %}{% ex = nil %}{% end %}
              {% if fm && fm[:format] %}{% fmt = fm[:format] %}{% else %}{% fmt = nil %}{% end %}
              {% if fm && fm[:max_length] %}{% max_len = fm[:max_length] %}{% else %}{% max_len = nil %}{% end %}
              {% if fm && fm[:min_length] %}{% min_len = fm[:min_length] %}{% else %}{% min_len = nil %}{% end %}
              {% if fm && !fm[:minimum].nil? %}{% minimum = fm[:minimum] %}{% else %}{% minimum = nil %}{% end %}
              {% if fm && !fm[:maximum].nil? %}{% maximum = fm[:maximum] %}{% else %}{% maximum = nil %}{% end %}
              {% if fm && fm[:enum] %}{% enum_vals = fm[:enum] %}{% else %}{% enum_vals = nil %}{% end %}
              {% if fm && !fm[:default].nil? %}{% default_val = fm[:default] %}{% else %}{% default_val = nil %}{% end %}

              {% if ivar_type.nilable? %}
                {% non_nil = ivar_type.union_types.reject { |t| t == Nil } %}
                {% if non_nil.size == 1 %}
                  {% inner = non_nil[0] %}
                  {% if inner == String %}
                    {{ ivar.name.stringify }} => {type: "string", nullable: true{% if fmt %}, format: {{ fmt }}{% end %}{% if ex %}, example: {{ ex }}{% end %}{% if max_len %}, maxLength: {{ max_len }}{% end %}{% if min_len %}, minLength: {{ min_len }}{% end %}{% if enum_vals %}, enum: {{ enum_vals }}{% end %}{% if default_val %}, default: {{ default_val }}{% end %}},
                  {% elsif inner == Int32 %}
                    {{ ivar.name.stringify }} => {type: "integer", format: {{ fmt || "int32" }}, nullable: true{% if ex %}, example: {{ ex }}{% end %}{% if minimum %}, minimum: {{ minimum }}{% end %}{% if maximum %}, maximum: {{ maximum }}{% end %}{% if default_val %}, default: {{ default_val }}{% end %}},
                  {% elsif inner == Int64 %}
                    {{ ivar.name.stringify }} => {type: "integer", format: {{ fmt || "int64" }}, nullable: true{% if ex %}, example: {{ ex }}{% end %}{% if minimum %}, minimum: {{ minimum }}{% end %}{% if maximum %}, maximum: {{ maximum }}{% end %}{% if default_val %}, default: {{ default_val }}{% end %}},
                  {% elsif inner == Float32 %}
                    {{ ivar.name.stringify }} => {type: "number", format: {{ fmt || "float" }}, nullable: true{% if ex %}, example: {{ ex }}{% end %}{% if minimum %}, minimum: {{ minimum }}{% end %}{% if maximum %}, maximum: {{ maximum }}{% end %}{% if default_val %}, default: {{ default_val }}{% end %}},
                  {% elsif inner == Float64 %}
                    {{ ivar.name.stringify }} => {type: "number", format: {{ fmt || "double" }}, nullable: true{% if ex %}, example: {{ ex }}{% end %}{% if minimum %}, minimum: {{ minimum }}{% end %}{% if maximum %}, maximum: {{ maximum }}{% end %}{% if default_val %}, default: {{ default_val }}{% end %}},
                  {% elsif inner == Bool %}
                    {{ ivar.name.stringify }} => {type: "boolean", nullable: true{% if ex %}, example: {{ ex }}{% end %}{% if default_val %}, default: {{ default_val }}{% end %}},
                  {% elsif inner == Time %}
                    {{ ivar.name.stringify }} => {type: "string", format: {{ fmt || "date-time" }}, nullable: true{% if ex %}, example: {{ ex }}{% end %}},
                  {% elsif inner.name(generic_args: false) == "Array" %}
                    {% el = inner.type_vars[0] %}
                    {% if el == String %}
                      {{ ivar.name.stringify }} => {type: "array", nullable: true, items: {type: "string"}{% if ex %}, example: {{ ex }}{% end %}},
                    {% elsif el == Int32 %}
                      {{ ivar.name.stringify }} => {type: "array", nullable: true, items: {type: "integer", format: "int32"}{% if ex %}, example: {{ ex }}{% end %}},
                    {% elsif el == Int64 %}
                      {{ ivar.name.stringify }} => {type: "array", nullable: true, items: {type: "integer", format: "int64"}{% if ex %}, example: {{ ex }}{% end %}},
                    {% elsif el == Float64 %}
                      {{ ivar.name.stringify }} => {type: "array", nullable: true, items: {type: "number", format: "double"}{% if ex %}, example: {{ ex }}{% end %}},
                    {% elsif el == Bool %}
                      {{ ivar.name.stringify }} => {type: "array", nullable: true, items: {type: "boolean"}{% if ex %}, example: {{ ex }}{% end %}},
                    {% elsif el.has_constant?("SwaggerSchema") %}
                      {% el_name = el.name(generic_args: false).split("::").last.gsub(/Serializer$/, "").gsub(/Schema$/, "") %}
                      {{ ivar.name.stringify }} => {type: "array", nullable: true, items: {"$ref" => "#/components/schemas/{{ el_name.id }}"}{% if ex %}, example: {{ ex }}{% end %}},
                    {% else %}
                      {% el_scalar_fmt = el.annotation(LuckySwagger::ScalarFormat) %}
                      {% if el_scalar_fmt %}
                        {{ ivar.name.stringify }} => {type: "array", nullable: true, items: {type: {{ el_scalar_fmt[:type] }}, format: {{ el_scalar_fmt[:format] }}}{% if ex %}, example: {{ ex }}{% end %}},
                      {% else %}
                        {{ ivar.name.stringify }} => {type: "array", nullable: true, items: {type: "object"}{% if ex %}, example: {{ ex }}{% end %}},
                      {% end %}
                    {% end %}
                  {% else %}
                    {% scalar_fmt = inner.annotation(LuckySwagger::ScalarFormat) %}
                    {% if scalar_fmt %}
                      {{ ivar.name.stringify }} => {type: {{ scalar_fmt[:type] }}, format: {{ scalar_fmt[:format] }}, nullable: true{% if ex %}, example: {{ ex }}{% end %}},
                    {% elsif inner.has_constant?("SwaggerSchema") %}
                      {{ ivar.name.stringify }} => SchemaIntrospector.openapi_schema({{ inner }}::SwaggerSchema),
                    {% else %}
                      {{ ivar.name.stringify }} => SchemaIntrospector.openapi_schema({{ inner }}),
                    {% end %}
                  {% end %}
                {% else %}
                  {{ ivar.name.stringify }} => {type: "string", nullable: true{% if ex %}, example: {{ ex }}{% end %}},
                {% end %}

              {% elsif ivar_type == String %}
                {{ ivar.name.stringify }} => {type: "string"{% if fmt %}, format: {{ fmt }}{% end %}{% if ex %}, example: {{ ex }}{% end %}{% if max_len %}, maxLength: {{ max_len }}{% end %}{% if min_len %}, minLength: {{ min_len }}{% end %}{% if enum_vals %}, enum: {{ enum_vals }}{% end %}{% if default_val %}, default: {{ default_val }}{% end %}},
              {% elsif ivar_type == Int32 %}
                {{ ivar.name.stringify }} => {type: "integer", format: {{ fmt || "int32" }}{% if ex %}, example: {{ ex }}{% end %}{% if minimum %}, minimum: {{ minimum }}{% end %}{% if maximum %}, maximum: {{ maximum }}{% end %}{% if default_val %}, default: {{ default_val }}{% end %}},
              {% elsif ivar_type == Int64 %}
                {{ ivar.name.stringify }} => {type: "integer", format: {{ fmt || "int64" }}{% if ex %}, example: {{ ex }}{% end %}{% if minimum %}, minimum: {{ minimum }}{% end %}{% if maximum %}, maximum: {{ maximum }}{% end %}{% if default_val %}, default: {{ default_val }}{% end %}},
              {% elsif ivar_type == Float32 %}
                {{ ivar.name.stringify }} => {type: "number", format: {{ fmt || "float" }}{% if ex %}, example: {{ ex }}{% end %}{% if minimum %}, minimum: {{ minimum }}{% end %}{% if maximum %}, maximum: {{ maximum }}{% end %}{% if default_val %}, default: {{ default_val }}{% end %}},
              {% elsif ivar_type == Float64 %}
                {{ ivar.name.stringify }} => {type: "number", format: {{ fmt || "double" }}{% if ex %}, example: {{ ex }}{% end %}{% if minimum %}, minimum: {{ minimum }}{% end %}{% if maximum %}, maximum: {{ maximum }}{% end %}{% if default_val %}, default: {{ default_val }}{% end %}},
              {% elsif ivar_type == Bool %}
                {{ ivar.name.stringify }} => {type: "boolean"{% if ex %}, example: {{ ex }}{% end %}{% if default_val %}, default: {{ default_val }}{% end %}},
              {% elsif ivar_type == Time %}
                {{ ivar.name.stringify }} => {type: "string", format: {{ fmt || "date-time" }}{% if ex %}, example: {{ ex }}{% end %}},
              {% elsif ivar_type.name(generic_args: false) == "Array" %}
                {% el = ivar_type.type_vars[0] %}
                {% if el == String %}
                  {{ ivar.name.stringify }} => {type: "array", items: {type: "string"}{% if ex %}, example: {{ ex }}{% end %}},
                {% elsif el == Int32 %}
                  {{ ivar.name.stringify }} => {type: "array", items: {type: "integer", format: "int32"}{% if ex %}, example: {{ ex }}{% end %}},
                {% elsif el == Int64 %}
                  {{ ivar.name.stringify }} => {type: "array", items: {type: "integer", format: "int64"}{% if ex %}, example: {{ ex }}{% end %}},
                {% elsif el == Float64 %}
                  {{ ivar.name.stringify }} => {type: "array", items: {type: "number", format: "double"}{% if ex %}, example: {{ ex }}{% end %}},
                {% elsif el == Bool %}
                  {{ ivar.name.stringify }} => {type: "array", items: {type: "boolean"}{% if ex %}, example: {{ ex }}{% end %}},
                {% elsif el.has_constant?("SwaggerSchema") %}
                  {% el_name = el.name(generic_args: false).split("::").last.gsub(/Serializer$/, "").gsub(/Schema$/, "") %}
                  {{ ivar.name.stringify }} => {type: "array", items: {"$ref" => "#/components/schemas/{{ el_name.id }}"}{% if ex %}, example: {{ ex }}{% end %}},
                {% else %}
                  {% el_scalar_fmt = el.annotation(LuckySwagger::ScalarFormat) %}
                  {% if el_scalar_fmt %}
                    {{ ivar.name.stringify }} => {type: "array", items: {type: {{ el_scalar_fmt[:type] }}, format: {{ el_scalar_fmt[:format] }}}{% if ex %}, example: {{ ex }}{% end %}},
                  {% else %}
                    {{ ivar.name.stringify }} => {type: "array", items: {type: "object"}{% if ex %}, example: {{ ex }}{% end %}},
                  {% end %}
                {% end %}
              {% else %}
                {% scalar_fmt = ivar_type.annotation(LuckySwagger::ScalarFormat) %}
                {% if scalar_fmt %}
                  {{ ivar.name.stringify }} => {type: {{ scalar_fmt[:type] }}, format: {{ scalar_fmt[:format] }}{% if ex %}, example: {{ ex }}{% end %}},
                {% elsif ivar_type.has_constant?("SwaggerSchema") %}
                  {{ ivar.name.stringify }} => SchemaIntrospector.openapi_schema({{ ivar_type }}::SwaggerSchema),
                {% else %}
                  {{ ivar.name.stringify }} => SchemaIntrospector.openapi_schema({{ ivar_type }}),
                {% end %}
              {% end %}
            {% end %}
          },
        }
      {% end %}
    end
  end
end
