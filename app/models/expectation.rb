class Expectation
  include Mongoid::Document
  cache

  field :css_class, :type => String
  field :text, :type => String
end

unless Expectation.all.count > 0

  Expectation.create :css_class=>"card_payment",  :text=>"Credit card required"
  Expectation.create :css_class=>"debit_card_payment",  :text=>"Debit card required"
  Expectation.create :css_class=>"debit_or_credit_card_payment",  :text=>"Debit or credit card required"
  Expectation.create :css_class=>"need_id",       :text=>"Proof of identification required"
  Expectation.create :css_class=>"need_passport", :text=>"A valid passport required"
  Expectation.create :css_class=>"need_ni",       :text=>"National Insurance number required"
  Expectation.create :css_class=>"need_address",  :text=>"3 years of address details required"
  Expectation.create :css_class=>"offline_steps", :text=>"Includes offline steps"
  Expectation.create :css_class=>"over_18",       :text=>"You must be over 18"
  Expectation.create :css_class=>"over_16",       :text=>"You must be over 16"
  Expectation.create :css_class=>"england_only",  :text=>"Available in England only"
  Expectation.create :css_class=>"england_wales", :text=>"Available in England and Wales only"
  Expectation.create :css_class=>"not_ni",        :text=>"Not available in Northern Ireland"

end
