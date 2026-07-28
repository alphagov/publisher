class HtmlRenderer
  def self.render_hash(hash)
    hash.each_value do |part|
      part[:body] = render_html(part[:body])
    end
  end

  def self.render_html(document)
    return "" if document.blank?

    html_content = Govspeak::Document.new(document).to_html
    references = ContentBlockTools::ContentBlockReference.find_all_in_document(html_content).uniq

    references.each do |ref|
      block = build_from_publishing_api(ref)
      html_content.gsub!(ref.embed_code, block.render)
    end

    html_content.strip
  end

  def self.build_from_publishing_api(reference)
    api_response = Services.publishing_api.get_content_items(
      content_id_aliases: [reference.identifier],
      document_type: reference.document_type,
    ).parsed_content["results"].first

    build_content_block(embed_code: reference.embed_code, api_response: api_response)
  end

  def self.build_content_block(embed_code:, api_response:)
    ContentBlockTools::ContentBlock.new(
      content_id: api_response["content_id"],
      title: api_response["title"],
      document_type: api_response["document_type"],
      details: api_response["details"],
      embed_code: embed_code,
    )
  end
end
