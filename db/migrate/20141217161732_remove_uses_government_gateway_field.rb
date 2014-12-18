class RemoveUsesGovernmentGatewayField < Mongoid::Migration
  def self.up
    Edition.all.each { |edition| edition.unset(:uses_government_gateway) }
  end

  def self.down
    # No down as this is a destructive action.
  end
end
