class RemoveUnusedCollections < Mongoid::Migration
  def self.up
    Mongoid.default_client['authorities'].drop
    Mongoid.default_client['local_transactions_source_lgsls'].drop
    Mongoid.default_client['local_transactions_sources'].drop
  end

  def self.down
  end
end
