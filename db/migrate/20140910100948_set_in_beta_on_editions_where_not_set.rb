class SetInBetaOnEditionsWhereNotSet < Mongoid::Migration
  def self.up
    number_of_editions_without_in_beta_field = Edition.where(:in_beta.exists => false).count
    puts "#{number_of_editions_without_in_beta_field} editions don't have the :in_beta field"

    result = Edition.where(:in_beta.exists => false).update_all(in_beta: false)
    puts "Updated #{result['n']} editions to have the :in_beta field set to false"
  end

  def self.down
  end
end
