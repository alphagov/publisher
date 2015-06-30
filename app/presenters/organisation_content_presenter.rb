class OrganisationContentPresenter < CSVPresenter
  def initialize(scope = Artefact.where(owning_app: "publisher"))
    super(scope)
    self.column_headings = [
      :id,
      :name,
      :slug,
      :state,
      :browse_pages,
      :primary_topic,
      :additional_topics,
      :organisation,
      :need_ids
    ]
  end

private

  def latest_edition_for(artefact)
    Edition.where(panopticon_id: artefact.id.to_s).desc(:created_at).first
  end

  def get_value(header, artefact)
    latest_edition = latest_edition_for(artefact)

    return super if latest_edition.nil?

    case header
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
