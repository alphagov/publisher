class MakeDraftTheDefaultState < Mongoid::Migration
  def self.up
    Edition.where(state: "lined_up").each do |edition|
      edition.state = "draft"
      edition.save!
    end
  end

  def self.down
    # No down, this is destructive
  end
end
