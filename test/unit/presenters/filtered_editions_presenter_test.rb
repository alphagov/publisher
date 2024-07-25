# frozen_string_literal: true

require "test_helper"

class FilteredEditionsPresenterTest < ActiveSupport::TestCase
  context "#editions" do
    should "return all editions when no filters are specified" do
      draft_guide = FactoryBot.create(:guide_edition, state: "draft")
      published_guide = FactoryBot.create(:guide_edition, state: "published")

      filtered_editions = FilteredEditionsPresenter.new(nil, nil).editions

      assert_equal(2, filtered_editions.count)
      assert_equal(draft_guide, filtered_editions[0])
      assert_equal(published_guide, filtered_editions[1])
    end

    should "filter by state" do
      draft_guide = FactoryBot.create(:guide_edition, state: "draft")
      FactoryBot.create(:guide_edition, state: "published")

      filtered_editions = FilteredEditionsPresenter.new(%w[draft], nil).editions

      assert_equal(1, filtered_editions.count)
      assert_equal(draft_guide, filtered_editions[0])
    end

    should "filter by 'assigned to'" do
      anna = FactoryBot.create(:user, name: "Anna")
      assigned_to_anna = FactoryBot.create(:guide_edition, assigned_to: anna.id)
      FactoryBot.create(:guide_edition)

      filtered_editions = FilteredEditionsPresenter.new(nil, anna.id).editions.to_a

      assert_equal([assigned_to_anna], filtered_editions)
    end

    should "filter by 'not assigned'" do
      anna = FactoryBot.create(:user, name: "Anna")
      FactoryBot.create(:guide_edition, assigned_to: anna.id)
      not_assigned = FactoryBot.create(:guide_edition)

      filtered_editions = FilteredEditionsPresenter.new(nil, "nobody").editions.to_a

      assert_equal([not_assigned], filtered_editions)
    end

    should "ignore invalid 'assigned to'" do
      anna = FactoryBot.create(:user, name: "Anna")
      FactoryBot.create(:guide_edition, assigned_to: anna.id)
      FactoryBot.create(:guide_edition)

      filtered_editions =
        FilteredEditionsPresenter.new(nil, "not a valid user id").editions

      assert_equal(2, filtered_editions.count)
    end
  end

  context "#available_users" do
    should "return users in alphabetical order" do
      bob = FactoryBot.create(:user, name: "Bob")
      charlie = FactoryBot.create(:user, name: "Charlie")
      anna = FactoryBot.create(:user, name: "Anna")

      users = FilteredEditionsPresenter.new(nil, nil).available_users.to_a

      assert_equal([anna, bob, charlie], users)
    end

    should "not include disabled users" do
      enabled_user = FactoryBot.create(:user, name: "enabled user")
      FactoryBot.create(:user, name: "disabled user", disabled: true)

      users = FilteredEditionsPresenter.new(nil, nil).available_users.to_a

      assert_equal(users, [enabled_user])
    end
  end
end
