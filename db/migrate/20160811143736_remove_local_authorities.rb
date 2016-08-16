class RemoveLocalAuthorities < Mongoid::Migration
  def self.up
    Mongoid.default_client['local_authorities'].drop
  end

  def self.down
  end
end
