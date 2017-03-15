class RepublishService
  def self.call(edition)
    UpdateService.call(edition, 'republish')
    PublishService.call(edition, 'republish')
  end
end
