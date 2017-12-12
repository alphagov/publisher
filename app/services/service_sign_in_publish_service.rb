class ServiceSignInPublishService
  def self.call(content)
    content_id = content.content_id
    Services.publishing_api.put_content(content_id, content.render_for_publishing_api)
    Services.publishing_api.patch_links(content_id, links: content.links)
    Services.publishing_api.publish(content_id)
  end
end
