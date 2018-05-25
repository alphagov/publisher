class RepublishService
  def self.call(edition)
    UpdateService.call(edition, republish: true)
    PublishService.call(edition, 'republish')
  end
end
