# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-05-10

This release introduces an inference-first architecture. A typical CRUD action now needs **zero annotations** to produce a correct OpenAPI spec.

### Added — Inference

- **IR-1** Auth mixin → security scheme inference. Map module names to scheme names via `settings.auth_mixin_map`; actions that include the mixin get `security:` automatically.
- **IR-2a** SaveOperation binding. `Foo::Create`/`Foo::Update` auto-bind to a top-level `SaveFoo` operation by convention; `@[LuckySwagger::Operation(SaveX)]` overrides when naming is non-conventional.
- **IR-3** Serializer → 200/201 response inference. `Foo::Show`/`Create`/`Update` actions auto-infer their response from `FooSerializer` with the correct status code and auto-422.
- **IR-4** Index → paginated collection inference. `Foo::Index` auto-wraps in `{items: [...], pagination: Pagination}`.
- **IR-7** Deprecation via `@[LuckySwagger::Endpoint(deprecated: true)]`. Crystal's built-in `@[Deprecated]` was considered and rejected (generates noisy macro use-site warnings).
- **IR-8** Tag generation config: `tag_strip_prefixes`, `tag_separator`, `default_tag` settings.

### Added — Explicit annotations (Phase 3)

- **EF-1** `@[Response(one_of: [...])`, `any_of:`, `all_of:` — polymorphic response schemas with `$ref` arrays.
- **EF-2** `@[LuckySwagger::HeaderParam(name:, type:, required:, description:)]` — stackable, emits `in: header`.
- **EF-3** `@[LuckySwagger::CookieParam(...)]` — same interface, emits `in: cookie`. Headers and cookies coexist on the same action.
- **EF-4** `@[RequestBody(multipart: {file: File, caption: String})]` — multipart/form-data request body; `File` → `format: binary`.
- **EF-5** `@[Response(N, content_type: "text/csv")]` — non-JSON content types; `schema: {type: "string"}` emitted automatically.
- **EF-6** `@[FieldMeta(example: ...)]` on `swagger_fields` properties; `@[Response(example: ...)]` on response annotations.
- **EF-7** `discriminator:` on `oneOf`/`anyOf` emits OpenAPI `discriminator: {propertyName: "..."}`.
- **EF-8** `settings.oauth2_schemes` with `OAuth2Scheme` / `OAuth2Flow` structs; camelCase keys serialized correctly; coexists with simple `security_schemes`.
- **EF-9** `@[Endpoint(external_docs: {url:, description:})]` — emits `externalDocs` on operations.
- **EF-10** `@[LuckySwagger::ScalarFormat(type:, format:)]` on custom types; `settings.format_map` for parameter type inference.
- **EF-11** Conditional/nullable fields: already covered by nilable types (`T?`) — no special syntax needed.
- **EF-12** `@[Endpoint(servers: [{url:, description:}])]` — per-operation servers override.
- **EF-15** `settings.contact`, `settings.license`, `settings.terms_of_service` — emitted into `info` object.

### Added — Schema definition (Phase 2)

- `field` macro inside `swagger_fields` — `property` with inline OpenAPI constraints: `max_length`, `min_length`, `minimum`, `maximum`, `enum`, `default`, `format`, `example`.
- Required/optional (`required:` array) is derived from nilability — non-nilable = required, nilable (`T?`) = optional. No annotation needed.

### Added — Tooling (Phase 4)

- `OpenApiGenerator.generate_json` — JSON output via YAML→Any→JSON.
- `--format json` flag on `lucky_swagger.generate_open_api` task.
- Alphabetical path ordering — generated `paths` keys are sorted, making diffs clean.
- `LuckySwagger::SpecValidator.validate(yaml)` / `validate!(yaml)` — checks structure and dangling `$ref` targets.
- `--validate` flag on `lucky_swagger.generate_open_api`.
- `LuckySwagger::LintSpec` task (`lucky lucky_swagger.lint_spec`) — runs Spectral if installed; prints install instructions otherwise.
- `WebHandler.new(live: true)` — generates spec on every request to `{swagger_url}/live.yaml`; no disk file needed.

### Changed

- TypeScript interface generation **removed** — use `openapi-typescript api.yaml > api.ts` on the generated spec instead.
- `WebHandler` constructor: `@folder` directory is no longer required in `live: true` mode; non-existent folder in file mode is handled gracefully (empty file list).
- `shard.yml` version bumped from `0.1.0` to `0.3.0`.

### Fixed

- `generate_open_api` task now writes correct YAML via `YAML.dump` directly to the file; no intermediate string allocation.
- `build_components` now merges `security_schemes` and `oauth2_schemes` into a single `securitySchemes` output block.

## [0.2.0] - 2025-xx-xx

Initial public release with basic annotation-driven spec generation, SwaggerUI serving, and route introspection.

## [0.1.0] - 2025-xx-xx

Initial private release.
