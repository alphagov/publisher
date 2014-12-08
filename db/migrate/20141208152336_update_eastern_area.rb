class UpdateEasternArea < Mongoid::Migration
  def self.up
    updated = []
    BusinessSupportEdition.where(:state.ne => "archived", :areas.in => ["east-of-england"]).each do |edition|
      unless edition.artefact.state == "archived"
        edition.areas[edition.areas.index("east-of-england")] = "eastern"
        updated << edition.slug if edition.save!(validate: false)
      end
    end
    puts "Updated #{updated.size} editions:"
    puts updated.join(", ")
  end

  def self.down
    BusinessSupportEdition.where(:state.ne => "archived", :areas.in => ["eastern"]).each do |edition|
      unless edition.artefact.state == "archived"
        edition.areas[edition.areas.index("eastern")] = "east-of-england"
        edition.save!(validate: false)
      end
    end
  end
end
