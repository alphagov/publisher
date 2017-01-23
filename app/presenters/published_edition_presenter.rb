class PublishedEditionPresenter
  def initialize(edition)
    @edition = edition
    @artefact = edition.artefact
  end

  def render_for_publishing_api(options={})
    if @artefact.generic_schema?
      render_for_generic_schema(options)
    else
      render_for_placeholder_content(options)
    end
  end

private

  def render_for_generic_schema(options)
    {
      title: @edition.title,
      base_path: base_path,
      description: @edition.overview || "",
      schema_name: "generic_with_external_related_links",
      document_type: @artefact.kind,
      need_ids: [],
      public_updated_at: public_updated_at,
      publishing_app: "publisher",
      rendering_app: "frontend",
      routes: routes,
      redirects: [],
      update_type: update_type(options),
      change_note: @edition.latest_change_note,
      details: {
        external_related_links: external_related_links,
      },
      locale: @artefact.language,
    }
  end

  def render_for_placeholder_content(options)
    {
      title: @edition.title,
      base_path: base_path,
      description: @edition.overview || "",
      schema_name: "placeholder",
      document_type: @artefact.kind,
      need_ids: [],
      public_updated_at: public_updated_at,
      publishing_app: "publisher",
      rendering_app: "frontend",
      routes: routes,
      redirects: [],
      update_type: update_type(options),
      details: {
        change_note: @edition.latest_change_note,
        external_related_links: external_related_links,
      },
      locale: @artefact.language,
    }
  end

  def external_related_links
    @edition.artefact.external_links.map do |link|
      {
        "url": link["url"],
        "title": link["title"]
      }
    end
  end

  def routes
    [
      { path: "#{base_path}", type: path_type },
      { path: "#{json_path}", type: "exact" }
    ]
  end

  def base_path
    "/#{@edition.slug}"
  end

  def json_path
    "#{base_path}.json"
  end

  def path_type
    case @edition.class
    when TransactionEdition, CampaignEdition, HelpPageEdition
      "exact"
    else
      "prefix"
    end
  end

  def update_type(options)
    if options[:republish]
      "republish"
    elsif major_change?
      "major"
    else
      "minor"
    end
  end

  def major_change?
    @edition.major_change || @edition.version_number == 1
  end

  def public_updated_at
    @edition.public_updated_at || @edition.updated_at
  end
end
