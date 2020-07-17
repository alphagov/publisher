desc "Imports services and removes any old ones"
task set_auth_bypass_id: :environment do
  Edition.all.each do |edition|
    edition.update(auth_bypass_id: edition.temp_auth_bypass_id)
  end
end
