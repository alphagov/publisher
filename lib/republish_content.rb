class RepublishContent
  def self.schedule_republishing
    Edition.published.each do |edition|
      PublishingAPINotifier.perform_async(edition.id.to_s, "republish")
    end
  end
end
