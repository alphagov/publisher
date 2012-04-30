module LocalServicesHelper
  def make_authority(tier, options)
    authority = FactoryGirl.create(:local_authority_with_contact, snac: options[:snac], tier: tier)
    add_service_interaction(authority, options[:lgsl]) if options[:lgsl]
    authority
  end

  def add_service_interaction(existing_authority, lgsl_code)
    FactoryGirl.create(:local_interaction, local_authority: existing_authority, lgsl_code: lgsl_code)
  end
  
  def make_service(lgsl_code, providing_tier)
    LocalService.create!(lgsl_code: lgsl_code, providing_tier: providing_tier)
  end

  def make_authority_providing(lgsl_code)
    council = FactoryGirl.create(:local_authority, snac: '00AA', tier: 'county')
    FactoryGirl.create(:local_interaction, local_authority: council, lgsl_code: lgsl_code)
    council
  end
end