class UnsetLocalAuthorityContactDetails < Mongoid::Migration
  def self.up
    LocalAuthority.all.each do |authority|
      authority.unset(:contact_address)
      authority.unset(:contact_phone)
      authority.unset(:contact_url)
      authority.unset(:contact_email)
      puts "unset contact details for #{authority.name}"
    end
  end

  def self.down
    # This is a destructive migration so the data can't be recovered from here.
    # Revert the associated changes to the LocalContactImporter and run that to
    # re-import the contact details instead.
  end
end
