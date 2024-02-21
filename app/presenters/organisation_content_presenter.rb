class OrganisationContentPresenter < CSVPresenter
  def initialize(scope = Artefact.where(owning_app: "publisher"))
    super(scope)
    self.column_headings = %i[
      id
      name
      format
      slug
      state
      browse_pages
      organisations
    ]
  end

private

  def artefact_contains_no_editions(artefact)
    artefact.latest_edition.nil?
  end

  def get_value(header, artefact)
    return super if artefact_contains_no_editions(artefact)

    content_id = artefact.content_id

    case header
    when :browse_pages
      expanded_links(content_id, %w[mainstream_browse_pages base_path], /\/browse\//)
    when :organisations
      expanded_links(content_id, %w[organisations title])
    when :format
      artefact.kind
    else
      super
    end
  end

  def expanded_links(content_id, keys, pattern_to_remove = nil)
    response = Services.publishing_api.get_expanded_links(content_id)
    join_strings(response.to_hash, keys, pattern_to_remove)
  rescue GdsApi::HTTPNotFound, GdsApi::HTTPClientError
    ""
  end

  def join_strings(response, keys, pattern_to_remove)
    results = response.fetch("expanded_links", {}).fetch(keys[0], {})
    values = results.map { |result| result.dig(*keys.drop(1)) }.compact
    values = values.map { |value| value.gsub(pattern_to_remove, "") } unless pattern_to_remove.nil?
    values.join(",")
  end
end
