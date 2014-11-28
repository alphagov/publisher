class FixErroneouslySyncedUsersWithEmptyPermissions < Mongoid::Migration
  def self.up
    User.where(:permissions => [], :created_at.gte => Time.zone.parse("27-Nov-2014 10:50")).delete_all
  end

  def self.down
  end
end
