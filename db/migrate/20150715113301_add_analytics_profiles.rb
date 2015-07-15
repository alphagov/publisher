class AddAnalyticsProfiles < Mongoid::Migration
  def self.up
    profiles = {
      'register-to-vote' => 'UA-23066786-5',
      'accelerated-possession-eviction' => 'UA-37377084-12',
      'renewtaxcredits' => 'UA-43414424-1',
      'registered-traveller' => 'UA-47583357-4',
    }

    profiles.each do |slug, profile|
      editions = TransactionEdition.where(slug: slug, :state.ne => 'archived')
      editions.each do |edition|
        edition.set(:department_analytics_profile, profile)
      end
    end
  end

  def self.down
  end
end
