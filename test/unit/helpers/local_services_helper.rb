module LocalServicesHelper
  def make_authority(tier, options)
    @next_id ||= 1 
    @next_id += 1
    authority = LocalAuthority.create!(
      name: "Some #{tier.capitalize} Council", 
      snac: options[:snac], 
      local_directgov_id: @next_id, 
      tier: tier
    )
    add_service_interaction(authority, options[:lgsl]) if options[:lgsl]
    authority
  end
  
  def add_service_interaction(existing_authority, lgsl_code)
    existing_authority.local_interactions.create!(
      url: "http://some.#{existing_authority.tier}.council.gov/do-#{lgsl_code}.html",
      lgsl_code: lgsl_code,
      lgil_code: 0)
  end
  
  def make_service(lgsl_code, providing_tier)
    LocalService.create!(lgsl_code: lgsl_code, providing_tier: providing_tier)
  end
end