class RepublishContent
  def self.schedule_republishing
    Edition.published.each do |edition|
      PublishingApiRepublisher.perform_async(edition.id.to_s, "republish")
    end
  end
end
