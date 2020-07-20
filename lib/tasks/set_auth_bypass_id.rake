desc "Imports services and removes any old ones"
task set_auth_bypass_id: :environment do
  Edition.all.each do |edition|
    # rubocop:disable Rails/SkipsModelValidations
    edition.update_attribute(:auth_bypass_id, edition.temp_auth_bypass_id)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
