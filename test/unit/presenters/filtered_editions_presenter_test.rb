# frozen_string_literal: true

require "test_helper"

class FilteredEditionsPresenterTest < ActiveSupport::TestCase
  context "#editions" do
    should "return all editions when no filters are specified" do
      draft_guide = FactoryBot.create(:guide_edition, state: "draft")
      published_guide = FactoryBot.create(:guide_edition, state: "published")

      filtered_editions = FilteredEditionsPresenter.new.editions

      assert_equal(2, filtered_editions.count)
      assert_equal(draft_guide, filtered_editions[0])
      assert_equal(published_guide, filtered_editions[1])
    end

    should "filter by state" do
      draft_guide = FactoryBot.create(:guide_edition, state: "draft")
      FactoryBot.create(:guide_edition, state: "published")

      filtered_editions = FilteredEditionsPresenter.new(states_filter: %w[draft]).editions

      assert_equal(1, filtered_editions.count)
      assert_equal(draft_guide, filtered_editions[0])
    end

    should "filter by 'assigned to'" do
      anna = FactoryBot.create(:user, name: "Anna")
      assigned_to_anna = FactoryBot.create(:guide_edition, assigned_to: anna.id)
      FactoryBot.create(:guide_edition)

      filtered_editions = FilteredEditionsPresenter.new(assigned_to_filter: anna.id).editions

      assert_equal([assigned_to_anna], filtered_editions.to_a)
    end

    should "filter by 'not assigned'" do
      anna = FactoryBot.create(:user, name: "Anna")
      FactoryBot.create(:guide_edition, assigned_to: anna.id)
      not_assigned = FactoryBot.create(:guide_edition)

      filtered_editions = FilteredEditionsPresenter.new(assigned_to_filter: "nobody").editions

      assert_equal([not_assigned], filtered_editions.to_a)
    end

    should "ignore invalid 'assigned to'" do
      anna = FactoryBot.create(:user, name: "Anna")
      FactoryBot.create(:guide_edition, assigned_to: anna.id)
      FactoryBot.create(:guide_edition)

      filtered_editions =
        FilteredEditionsPresenter.new(assigned_to_filter: "not a valid user id").editions

      assert_equal(2, filtered_editions.count)
    end

    should "filter by format" do
      guide = FactoryBot.create(:guide_edition)
      FactoryBot.create(:completed_transaction_edition)

      filtered_editions = FilteredEditionsPresenter.new(format_filter: "guide").editions

      assert_equal([guide], filtered_editions.to_a)
    end

    should "return all formats when specified by the format filter" do
      FactoryBot.create(:guide_edition)
      FactoryBot.create(:completed_transaction_edition)

      filtered_editions = FilteredEditionsPresenter.new(format_filter: "all").editions

      assert_equal(2, filtered_editions.count)
    end

    should "filter by a partially-matching title" do
      guide_fawkes = FactoryBot.create(:guide_edition, title: "Guide Fawkes")
      FactoryBot.create(:guide_edition, title: "Hitchhiker's Guide")

      filtered_editions = FilteredEditionsPresenter.new(title_filter: "Fawkes").editions

      assert_equal([guide_fawkes], filtered_editions.to_a)
    end

    should "not return popular links" do
      guide_fawkes = FactoryBot.create(:guide_edition)
      FactoryBot.create(:popular_links)

      filtered_editions = FilteredEditionsPresenter.new.editions

      assert_equal([guide_fawkes], filtered_editions.to_a)
    end

    should "return a single 'page' of results when no page number is specified" do
      FactoryBot.create_list(:guide_edition, FilteredEditionsPresenter::ITEMS_PER_PAGE + 1)

      filtered_editions = FilteredEditionsPresenter.new.editions

      assert_equal(FilteredEditionsPresenter::ITEMS_PER_PAGE + 1, filtered_editions.count)
      assert_equal(FilteredEditionsPresenter::ITEMS_PER_PAGE, filtered_editions.to_a.count)
    end

    should "return the specified 'page' of results" do
      FactoryBot.create_list(:guide_edition, FilteredEditionsPresenter::ITEMS_PER_PAGE + 1)

      filtered_editions = FilteredEditionsPresenter.new(page: 2).editions

      assert_equal(1, filtered_editions.to_a.count)
    end
  end

  context "#available_users" do
    should "return users in alphabetical order" do
      bob = FactoryBot.create(:user, name: "Bob")
      charlie = FactoryBot.create(:user, name: "Charlie")
      anna = FactoryBot.create(:user, name: "Anna")

      users = FilteredEditionsPresenter.new.available_users.to_a

      assert_equal([anna, bob, charlie], users)
    end

    should "not include disabled users" do
      enabled_user = FactoryBot.create(:user, name: "enabled user")
      FactoryBot.create(:user, name: "disabled user", disabled: true)

      users = FilteredEditionsPresenter.new.available_users.to_a

      assert_equal(users, [enabled_user])
    end
  end
end
