class OrganisationContentPresenter < CSVPresenter
  include PathsHelper

  def initialize(scope = Artefact.where(owning_app: "publisher"))
    super(scope)
    self.column_headings = [
      :id,
      :name,
      :url,
      :state,
      :browse_pages,
      :primary_topic,
      :additional_topics,
      :organisation,
      :need_ids
    ]

    @edition_cache = {}
  end

private

  def get_value(header, artefact)
    latest_edition = (
      @edition_cache[artefact.id] ||= Edition.where(panopticon_id: artefact.id).desc(:created_at).last
    )

    return super if latest_edition.nil?

    case header
    when :url
      preview_edition_path(latest_edition)
    when :browse_pages
      latest_edition.browse_pages.join(",")
    when :primary_topic
      latest_edition.primary_topic
    when :additional_topics
      latest_edition.additional_topics.join(",")
    when :organisation
      artefact.department
    when :need_ids
      artefact.need_ids.join(',')
    else
      super
    end
  end
end
