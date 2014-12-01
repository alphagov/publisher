class MoveExpectationsToNeedToKnowField < Mongoid::Migration
  def self.up
    [PlaceEdition, TransactionEdition, LocalTransactionEdition].each do |edition_class|
      edition_class.where(:expectation_ids.nin => [[], [""]]).each do |edition|
        edition.set(:need_to_know, expectations_to_govspeak(edition.expectation_ids))
      end
    end
  end

  def self.expectations_to_govspeak(expectation_ids)
    # turn expectations into an unordered list
    relevant_expectations = expectations.values_at(*expectation_ids).compact
    relevant_expectations.present? ? relevant_expectations.map { |ex| "- #{ex}\r\n" }.join : nil
  end

  def self.expectations
    @@expectations ||= Expectation.all.inject({}) { |result, ex| result[ex.id.to_s] = ex.text; result }
  end
end

class Expectation
  include Mongoid::Document
  field :text, type: String
end
