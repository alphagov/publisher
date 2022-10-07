module LocalServicesHelper
  def make_service(lgsl_code, providing_tier)
    LocalService.create!(lgsl_code:, providing_tier:)
  end
end
