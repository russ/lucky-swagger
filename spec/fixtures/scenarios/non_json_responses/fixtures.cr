module NonJsonResponsesScenario
  # CSV download
  @[LuckySwagger::Response(200, content_type: "text/csv", description: "CSV export")]
  class CsvExport < ScenarioAction
    get "/scenarios/non-json-responses/export.csv" do
      plain_text "ok"
    end
  end

  # Plain text
  @[LuckySwagger::Response(200, content_type: "text/plain")]
  class PlainText < ScenarioAction
    get "/scenarios/non-json-responses/ping" do
      plain_text "ok"
    end
  end

  # Custom binary content type
  @[LuckySwagger::Response(200, content_type: "application/pdf", description: "PDF report")]
  class PdfDownload < ScenarioAction
    get "/scenarios/non-json-responses/report.pdf" do
      plain_text "ok"
    end
  end

  # Mixed: non-JSON 200 + explicit JSON 422
  @[LuckySwagger::Response(200, content_type: "text/csv")]
  @[LuckySwagger::Response(422, schema: LuckySwagger::ErrorSchema)]
  class CsvWithErrors < ScenarioAction
    post "/scenarios/non-json-responses/export-with-errors" do
      plain_text "ok"
    end
  end
end
