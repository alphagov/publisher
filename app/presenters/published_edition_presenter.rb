# PublishedEditionPresenter generates the payload we'll send to
# the Publishing API.
class PublishedEditionPresenter
  def initialize(edition)
    @edition = edition
    @artefact = edition.artefact
  end

  def content_id
    @artefact.content_id
  end

  def payload
    {
      title: @edition.title,
      base_path: base_path,
      description: @edition.overview || "",
      format: "placeholder",
      need_ids: [],
      public_updated_at: @edition.public_updated_at,
      publishing_app: "publisher",
      rendering_app: "frontend",
      routes: [
        {path: base_path, type: "exact"}
      ],
      redirects: [],
      details: {
        change_note: @edition.latest_change_note,
        tags: {
          browse_pages: @edition.browse_pages,
          primary_topic: [@edition.primary_topic],
          additional_topics: @edition.additional_topics,
          topics: [@edition.primary_topic] + @edition.additional_topics,
        }
      },
      locale: 'en',
    }
  end

private

  def base_path
    "/#{@edition.slug}"
  end
end
