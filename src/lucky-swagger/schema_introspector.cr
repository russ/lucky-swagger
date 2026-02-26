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

              {% if ivar_type.nilable? %}
                {% non_nil = ivar_type.union_types.reject { |t| t == Nil } %}
                {% if non_nil.size == 1 %}
                  {% inner = non_nil[0] %}
                  {% if inner == String %}
                    {{ ivar.name.stringify }} => {type: "string", nullable: true},
                  {% elsif inner == Int32 %}
                    {{ ivar.name.stringify }} => {type: "integer", format: "int32", nullable: true},
                  {% elsif inner == Int64 %}
                    {{ ivar.name.stringify }} => {type: "integer", format: "int64", nullable: true},
                  {% elsif inner == Float32 %}
                    {{ ivar.name.stringify }} => {type: "number", format: "float", nullable: true},
                  {% elsif inner == Float64 %}
                    {{ ivar.name.stringify }} => {type: "number", format: "double", nullable: true},
                  {% elsif inner == Bool %}
                    {{ ivar.name.stringify }} => {type: "boolean", nullable: true},
                  {% elsif inner == Time %}
                    {{ ivar.name.stringify }} => {type: "string", format: "date-time", nullable: true},
                  {% elsif inner.name(generic_args: false) == "Array" %}
                    {% el = inner.type_vars[0] %}
                    {% if el == String %}
                      {{ ivar.name.stringify }} => {type: "array", nullable: true, items: {type: "string"}},
                    {% elsif el == Int32 %}
                      {{ ivar.name.stringify }} => {type: "array", nullable: true, items: {type: "integer", format: "int32"}},
                    {% elsif el == Int64 %}
                      {{ ivar.name.stringify }} => {type: "array", nullable: true, items: {type: "integer", format: "int64"}},
                    {% elsif el == Float64 %}
                      {{ ivar.name.stringify }} => {type: "array", nullable: true, items: {type: "number", format: "double"}},
                    {% elsif el == Bool %}
                      {{ ivar.name.stringify }} => {type: "array", nullable: true, items: {type: "boolean"}},
                    {% else %}
                      {{ ivar.name.stringify }} => {type: "array", nullable: true, items: {type: "object"}},
                    {% end %}
                  {% else %}
                    {{ ivar.name.stringify }} => {type: "object", nullable: true},
                  {% end %}
                {% else %}
                  {{ ivar.name.stringify }} => {type: "string", nullable: true},
                {% end %}

              {% elsif ivar_type == String %}
                {{ ivar.name.stringify }} => {type: "string"},
              {% elsif ivar_type == Int32 %}
                {{ ivar.name.stringify }} => {type: "integer", format: "int32"},
              {% elsif ivar_type == Int64 %}
                {{ ivar.name.stringify }} => {type: "integer", format: "int64"},
              {% elsif ivar_type == Float32 %}
                {{ ivar.name.stringify }} => {type: "number", format: "float"},
              {% elsif ivar_type == Float64 %}
                {{ ivar.name.stringify }} => {type: "number", format: "double"},
              {% elsif ivar_type == Bool %}
                {{ ivar.name.stringify }} => {type: "boolean"},
              {% elsif ivar_type == Time %}
                {{ ivar.name.stringify }} => {type: "string", format: "date-time"},
              {% elsif ivar_type.name(generic_args: false) == "Array" %}
                {% el = ivar_type.type_vars[0] %}
                {% if el == String %}
                  {{ ivar.name.stringify }} => {type: "array", items: {type: "string"}},
                {% elsif el == Int32 %}
                  {{ ivar.name.stringify }} => {type: "array", items: {type: "integer", format: "int32"}},
                {% elsif el == Int64 %}
                  {{ ivar.name.stringify }} => {type: "array", items: {type: "integer", format: "int64"}},
                {% elsif el == Float64 %}
                  {{ ivar.name.stringify }} => {type: "array", items: {type: "number", format: "double"}},
                {% elsif el == Bool %}
                  {{ ivar.name.stringify }} => {type: "array", items: {type: "boolean"}},
                {% else %}
                  {{ ivar.name.stringify }} => {type: "array", items: {type: "object"}},
                {% end %}
              {% else %}
                {{ ivar.name.stringify }} => {type: "object"},
              {% end %}
            {% end %}
          },
        }
      {% end %}
    end

    # Generate TypeScript interface from Crystal struct
    macro typescript_interface(type, interface_name = nil)
      {% name = interface_name || type.name.split("::").last %}
      String.build do |str|
        str << "export interface " << {{ name.id.stringify }} << " {\n"
        {% for ivar in type.instance_vars %}
          {% is_optional = ivar.type.union? && ivar.type.union_types.includes?(Nil) %}
          str << "  " << {{ ivar.name.stringify }} << {% if is_optional %}"?"{% end %} << ": "
          str << {{ crystal_type_to_typescript(ivar.type) }}
          {% if ivar.annotation(::JSON::Field) && ivar.annotation(::JSON::Field)[:description] %}
            str << "; // " << {{ ivar.annotation(::JSON::Field)[:description] }}
          {% end %}
          str << "\n"
        {% end %}
        str << "}\n"
      end
    end

    # Convert Crystal type to TypeScript type
    macro crystal_type_to_typescript(crystal_type)
      {% if crystal_type == String %}
        "string"
      {% elsif crystal_type == Int32 || crystal_type == Int64 || crystal_type == Float32 || crystal_type == Float64 %}
        "number"
      {% elsif crystal_type == Bool %}
        "boolean"
      {% elsif crystal_type == Time %}
        "string"
      {% elsif crystal_type.union? %}
        {% non_nil_types = crystal_type.union_types.reject { |t| t == Nil } %}
        {% if non_nil_types.size == 1 %}
          {{ crystal_type_to_typescript(non_nil_types[0]) }}
        {% else %}
          "string"
        {% end %}
      {% elsif crystal_type.stringify.starts_with?("Array(") %}
        {% element_type = crystal_type.type_vars[0] %}
        {{ crystal_type_to_typescript(element_type) }} + "[]"
      {% else %}
        {{ crystal_type.name.split("::").last.stringify }}
      {% end %}
    end

    # Extract example JSON from a struct instance
    macro example_json(instance)
      {{ instance }}.to_json
    end
  end
end
