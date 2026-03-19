class HtmlRenderer
  def self.render_hash(hash)
    hash.transform_values { |v| render_html(v) }
  end

  def self.render_html(document)
    return "" if document.blank?

    html_content = Govspeak::Document.new(document).to_html

    ContentBlockTools::ContentBlockReference.find_all_in_document(html_content).each do |content_block|
      html_content.gsub!(content_block.embed_code, render_content_block(content_block.embed_code))
    end

    html_content.strip
  end

  def self.render_content_block(ref)
    ContentBlockTools::ContentBlock.from_embed_code(ref).render
  end
end
