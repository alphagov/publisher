# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
Expectation.create :css_class=>"card_payment",  :text=>"Credit card required"
Expectation.create :css_class=>"debit_card_payment",  :text=>"Debit card required"
Expectation.create :css_class=>"debit_or_credit_card_payment",  :text=>"Debit or Credit card required"
Expectation.create :css_class=>"need_id",       :text=>"Proof of identification required"
Expectation.create :css_class=>"need_passport", :text=>"A valid passport required"
Expectation.create :css_class=>"need_ni",       :text=>"National Insurance Number required"
Expectation.create :css_class=>"need_address",  :text=>"3 years of address details required"
Expectation.create :css_class=>"offline_steps", :text=>"Includes offline steps"
Expectation.create :css_class=>"over_18",       :text=>"You must be over 18"
Expectation.create :css_class=>"over_16",       :text=>"You must be over 16"
Expectation.create :css_class=>"england_only",  :text=>"Available in England only"
Expectation.create :css_class=>"england_wales", :text=>"Available in England and Wales only"
Expectation.create :css_class=>"not_ni",        :text=>"Not available in Northern Ireland"

User.create :name => 'Winston', :uid => 'winston', :version => 1, :email => 'winston@alphagov.co.uk'