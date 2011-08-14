module Expectant

  module ClassMethods
    def expectation_choices
      Hash[Expectation.all.map {|e| [e.text,e._id.to_s] }]
    end
  end
    
  extend ActiveSupport::Concern
  
  included do 
    field :expectation_ids, :type => Array, :default => []
  end
  
  def expectations
    Expectation.criteria.in(:_id => self.expectation_ids)
  end  

end
