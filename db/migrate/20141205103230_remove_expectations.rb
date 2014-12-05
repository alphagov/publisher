class RemoveExpectations < Mongoid::Migration
  def self.up
    Edition.where(:expectation_ids.exists => true).each { |e| e.unset(:expectation_ids) }
    Mongoid.master.collection(:expectations).drop
  end

  def self.down
  end
end
