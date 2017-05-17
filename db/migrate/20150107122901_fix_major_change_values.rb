class FixMajorChangeValues < Mongoid::Migration
  def self.up
    Edition.collection.update(
      { "major_change" => nil },
      { "$set" => { "major_change" => false } },
      multi: true
    )
  end

  def self.down
  end
end
