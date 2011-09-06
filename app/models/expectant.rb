module Expectant

  module ClassMethods
    def expectation_choices
      Hash[Expectation.all.map {|e| [e.text,e._id.to_s] }]
    end
  end

  extend ActiveSupport::Concern

  included do
    field :expectation_ids, :type => Array, :default => []
    field :minutes_to_complete, :type => String
    field :uses_government_gateway, :type => Boolean
  end

  def expectations
    Expectation.criteria.in(:_id => self.expectation_ids)
  end

end
