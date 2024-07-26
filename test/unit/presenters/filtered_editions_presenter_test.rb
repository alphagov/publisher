# frozen_string_literal: true

require "test_helper"

class FilteredEditionsPresenterTest < ActiveSupport::TestCase
  context "#editions" do
    should "return all editions when no filters are specified" do
      draft_guide = FactoryBot.create(:guide_edition, state: "draft")
      published_guide = FactoryBot.create(:guide_edition, state: "published")

      filtered_editions = FilteredEditionsPresenter.new(nil).editions

      assert_equal(2, filtered_editions.count)
      assert_equal(draft_guide, filtered_editions[0])
      assert_equal(published_guide, filtered_editions[1])
    end

    should "filter by state" do
      draft_guide = FactoryBot.create(:guide_edition, state: "draft")
      FactoryBot.create(:guide_edition, state: "published")

      filtered_editions = FilteredEditionsPresenter.new(%w[draft]).editions

      assert_equal(1, filtered_editions.count)
      assert_equal(draft_guide, filtered_editions[0])
    end
  end
end
