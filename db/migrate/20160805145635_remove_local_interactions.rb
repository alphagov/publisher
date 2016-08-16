class RemoveLocalInteractions < Mongoid::Migration
  def self.up
    # The next migration removes this collection entirely, and the model at
    # this point is gone, so this line fails.
    # LocalAuthority.all.each { |la| la.unset(:local_interactions) }
  end

  def self.down
    # No down, this is destructive
  end
end
