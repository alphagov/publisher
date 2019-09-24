class KnowledgeApi
  CONTENT_ID = "4dbbc2d1-a0db-441b-96c9-a743d067f724".freeze
  KNOWLEDGE_ENTRIES = YAML.load_file(Rails.root.join("app", "services", "knowledge_api.yml")).freeze

  def publish
    Services.publishing_api.put_content(CONTENT_ID, payload)
    Services.publishing_api.publish(CONTENT_ID, "major")
  end

  def payload
    {
      base_path: "/knowledge-alpha",
      title: "Experimental knowledge API",
      document_type: "knowledge_alpha",
      phase: "alpha",
      publishing_app: "publisher",
      rendering_app: "frontend",
      schema_name: "knowledge_alpha",
      details: {
        entries: KNOWLEDGE_ENTRIES,
      },
      routes: [
        { path: "/knowledge-alpha", type: "exact" },
      ],
    }
  end
end
