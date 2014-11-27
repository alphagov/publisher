require 'test_helper'
require 'csv'

class TopicChanges::PreparerTest < ActiveSupport::TestCase

  setup do
    @source_topic_id = 'tea/yorkshire'
    @destination_topic_id = 'tea/lancashire'

    @preparer = TopicChanges::Preparer.new(@source_topic_id, @destination_topic_id)
  end

  should 'return a CSV of slugs tagged to the source topics' do
    editions = [
      FactoryGirl.create_list(:answer_edition, 3, primary_topic: @source_topic_id),
      FactoryGirl.create_list(:answer_edition, 3, additional_topics: [@source_topic_id])
    ].flatten
    output = @preparer.build_csv

    editions.each do |edition|
      # match the full expected row in the CSV output
      expected_match = Regexp.new("^#{edition.slug},#{@source_topic_id},#{@destination_topic_id}$")

      assert expected_match.match(output)
    end
  end

  should 'exclude slugs which are not tagged to the topic' do
    excluded_editions = FactoryGirl.create_list(:answer_edition, 3,
                          primary_topic: nil,
                          additional_topics: [],
                        )
    output = @preparer.build_csv

    excluded_editions.each do |edition|
      prohibited_match = Regexp.new("^#{edition.slug}")

      refute prohibited_match.match(output)
    end
  end

end
