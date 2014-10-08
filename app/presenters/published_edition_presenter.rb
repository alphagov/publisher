class PublishedEditionPresenter
  def initialize(edition)
    @edition = edition
  end

  def render_for_publishing_api
    {
      title: @edition.title,
      base_path: base_path,
      description: @edition.overview,
      format: "placeholder",
      need_ids: [],
      public_updated_at: @edition.updated_at,
      publishing_app: "publisher",
      rendering_app: "frontend",
      routes: [
        {path: base_path, type: "exact"}
      ],
      redirects: [],
      update_type: update_type,
      details: {
        change_note: "",
        tags: { # Coming soon
          browse_pages: [],
          topics: [],
        }
      }
    }
  end

private

  def base_path
    "/#{@edition.slug}"
  end

  def update_type
    @edition.fact_check_skipped? ? "minor" : "major"
  end
end
