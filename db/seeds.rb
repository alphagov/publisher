# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
Expectation.create :text=>"Credit card required"
Expectation.create :text=>"Debit card required"
Expectation.create :text=>"Debit or Credit card required"
Expectation.create :text=>"Proof of identification required"
Expectation.create :text=>"A valid passport required"
Expectation.create :text=>"National Insurance Number required"
Expectation.create :text=>"3 years of address details required"
Expectation.create :text=>"Includes offline steps"
Expectation.create :text=>"You must be over 18"
Expectation.create :text=>"You must be over 16"
Expectation.create :text=>"Available in England only"
Expectation.create :text=>"Available in England and Wales only"
Expectation.create :text=>"Not available in Northern Ireland"

User.create :name => 'Winston', :uid => 'winston', :version => 1, :email => 'winston@alphagov.co.uk'

Dir[File.join(File.dirname(__FILE__),'seeds', '*.rb')].each do |f|
  puts "Seeding from #{ File.basename f }..."
  load f
  puts "Done."
end
