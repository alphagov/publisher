class RemoveLocalInteractions < Mongoid::Migration
  def self.up
    LocalAuthority.all.each { |la| la.unset(:local_interactions) }
  end

  def self.down
    # No down, this is destructive
  end
end
