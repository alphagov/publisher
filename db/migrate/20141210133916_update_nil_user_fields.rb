class UpdateNilUserFields < Mongoid::Migration
  # Clear up this legacy empty user account.
  # The user has no name, email or uid and is possibly
  # a convenient way to unassign content.
  #
  def self.up
    user = User.find('4fdef980a4254a0ef6000001')
    user.uid = '42'
    user.name = 'Nil (deprecated)'
    user.disabled = true
    user.save!
  end

  def self.down
  end
end
