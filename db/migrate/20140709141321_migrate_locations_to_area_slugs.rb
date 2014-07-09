class MigrateLocationsToAreaSlugs < Mongoid::Migration
  def self.up
    BusinessSupportLocationMigrator.run
  end

  def self.down
    BusinessSupportEdition.excludes(state: 'archived').each do |bs|
      unless bs.artefact.state == 'archived'
        bs.areas = []
        bs.save(validate: false)
      end
    end
  end
end
