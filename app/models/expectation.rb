class Expectation
  include Mongoid::Document
  cache
  
  field :css_class, :type => String
  field :text, :type => String
  
end


#Expectation.destroy_all
unless Expectation.all.count > 0
  
  Expectation.create :css_class=>"less_than_10",  :text=>"Less than 10 minutes"             
  Expectation.create :css_class=>"less_than_20",  :text=>"Less than 20 minutes"                        
  Expectation.create :css_class=>"less_than_30",  :text=>"Less than 30 minutes"                        
  Expectation.create :css_class=>"less_than_40",  :text=>"Less than 40 minutes"                        
  Expectation.create :css_class=>"gateway",       :text=>"Government Gateway"                        
  Expectation.create :css_class=>"card_payment",  :text=>"Credit card required"                        
  Expectation.create :css_class=>"need_id",       :text=>"Proof of identification required"            
  Expectation.create :css_class=>"need_passport", :text=>"A valid passport required"             
  Expectation.create :css_class=>"need_ni",       :text=>"National Insurance Number required"        
  Expectation.create :css_class=>"need_address",  :text=>"Three years of address details required"   
  Expectation.create :css_class=>"over_18",       :text=>"You must be over 18"      
  Expectation.create :css_class=>"offline_steps", :text=>"Includes offline steps"                      

end