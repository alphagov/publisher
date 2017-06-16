module LocalServicesHelper
  def make_service(lgsl_code, providing_tier)
    LocalService.create!(lgsl_code: lgsl_code, providing_tier: providing_tier)
  end
end
