class MigrateBsfAreasToSlugs < Mongoid::Migration
  def self.up
    BusinessSupportEdition.excludes(state: 'archived').order_by(:slug).each do |bs|
      next if bs.artefact.state == 'archived'
      bs.areas = bs.locations
      bs.save(validate: false)
    end
  end

  def self.down
    BusinessSupportEdition.excludes(state: 'archived').order_by(:slug).each do |bs|
      next if bs.artefact.state == 'archived'
      bs.areas = []
      bs.save(validate: false)
    end
  end
end
