class HtmlRenderer
  def self.render_hash(hash)
    hash.each_value do |part|
      part[:body] = render_html(part[:body])
    end
  end

  def self.render_html(document)
    return "" if document.blank?

    html_content = Govspeak::Document.new(document).to_html

    ContentBlockTools::ContentBlockReference.find_all_in_document(html_content).each do |content_block|
      code = content_block.embed_code
      html_content.gsub!(code, ContentBlockTools::ContentBlock.from_embed_code(code).render)
    end

    html_content.strip
  end
end
