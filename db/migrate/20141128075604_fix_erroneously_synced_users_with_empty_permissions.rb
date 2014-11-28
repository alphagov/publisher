class FixErroneouslySyncedUsersWithEmptyPermissions < Mongoid::Migration
  def self.up
    User.delete_all(:permissions => [], :created_at.gte => Time.zone.parse("27-Nov-2014 10:50"))
  end

  def self.down
  end
end
