class FixPartOrdering < Mongoid::Migration
  def self.up
    count = 0

    Edition.skip_callback(:save, :before, :check_for_archived_artefact)

    Edition.all.each do |edition|
      next unless edition.is_a?(Parted)
      if edition.parts.map(&:order).any?(&:nil?)
        puts "Fixing nil parts order for #{edition.title}(v#{edition.version_number})"
        puts "  broken order was: #{edition.parts.map(&:order).inspect}"
        edition.order_parts
        edition.save! :validate => false # skip validations so that we can fix published and archived editions
        count += 1
      end
    end
    puts "#{count} Editions fixed"
  end

  def self.down
  end
end
