# frozen_string_literal: true

require "test_helper"

class FilteredEditionsPresenterTest < ActiveSupport::TestCase
  def a_gds_user
    FactoryBot.create(:user, organisation_content_id: PublishService::GDS_ORGANISATION_ID)
  end

  context "#content_types" do
    should "return content types with none selected when no content type filter has been specified" do
      content_types = FilteredEditionsPresenter.new(a_gds_user).content_types

      assert_equal(13, content_types.count)
      assert_includes(content_types, { text: "All", value: "all" })
      assert_includes(content_types, { text: "Answer", value: "answer" })
      assert_includes(content_types, { text: "Campaign (Retired)", value: "campaign" })
      assert_includes(content_types, { text: "Completed transaction", value: "completed_transaction" })
      assert_includes(content_types, { text: "Guide", value: "guide" })
      assert_includes(content_types, { text: "Help page", value: "help_page" })
      assert_includes(content_types, { text: "Licence (Retired)", value: "licence" })
      assert_includes(content_types, { text: "Local transaction", value: "local_transaction" })
      assert_includes(content_types, { text: "Place", value: "place" })
      assert_includes(content_types, { text: "Programme (Retired)", value: "programme" })
      assert_includes(content_types, { text: "Simple smart answer", value: "simple_smart_answer" })
      assert_includes(content_types, { text: "Transaction", value: "transaction" })
      assert_includes(content_types, { text: "Video (Retired)", value: "video" })
    end

    should "mark the relevant content type as selected when a content type filter has been specified" do
      content_types = FilteredEditionsPresenter.new(a_gds_user, content_type_filter: "answer").content_types

      assert_includes(content_types, { text: "Answer", value: "answer", selected: "true" })
      assert_includes(content_types, { text: "Place", value: "place" }) # Not selected
    end
  end

  context "#edition_states" do
    should "return states with none checked when no state filter has been specified" do
      states = FilteredEditionsPresenter.new(a_gds_user).edition_states

      assert_equal(9, states.count)
      assert_includes(states, { label: "Drafts", value: :draft })
      assert_includes(states, { label: "In review", value: :in_review })
      assert_includes(states, { label: "Amends needed", value: :amends_needed })
      assert_includes(states, { label: "Out for fact check", value: :fact_check })
      assert_includes(states, { label: "Fact check received", value: :fact_check_received })
      assert_includes(states, { label: "Ready", value: :ready })
      assert_includes(states, { label: "Scheduled", value: :scheduled_for_publishing })
      assert_includes(states, { label: "Published", value: :published })
      assert_includes(states, { label: "Archived", value: :archived })
    end

    should "mark the relevant states as checked when a state filter has been specified" do
      states = FilteredEditionsPresenter.new(a_gds_user, states_filter: %w[in_review ready]).edition_states

      assert_includes(states, { label: "In review", value: :in_review, checked: "true" })
      assert_includes(states, { label: "Ready", value: :ready, checked: "true" })
      assert_includes(states, { label: "Published", value: :published }) # Not checked
    end
  end

  context "#editions" do
    should "return all editions when no filters are specified" do
      draft_guide = FactoryBot.create(:guide_edition, state: "draft")
      published_guide = FactoryBot.create(:guide_edition, state: "published")

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user).editions

      assert_equal(2, filtered_editions.count)
      assert_includes(filtered_editions, draft_guide)
      assert_includes(filtered_editions, published_guide)
    end

    should "filter by state" do
      draft_guide = FactoryBot.create(:guide_edition, state: "draft")
      FactoryBot.create(:guide_edition, state: "published")

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user, states_filter: %w[draft]).editions

      assert_equal(1, filtered_editions.count)
      assert_equal(draft_guide, filtered_editions[0])
    end

    should "filter by 'assigned to'" do
      anna = FactoryBot.create(:user, name: "Anna")
      # reference: note_for_postgres_migration
      assigned_to_anna = FactoryBot.create(:guide_edition, assigned_to_id: anna.id)
      FactoryBot.create(:guide_edition)

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user, assigned_to_filter: anna.id).editions

      assert_equal([assigned_to_anna], filtered_editions.to_a)
    end

    should "filter by 'not assigned'" do
      anna = FactoryBot.create(:user, name: "Anna")
      # reference: note_for_postgres_migration
      FactoryBot.create(:guide_edition, assigned_to_id: anna.id)
      not_assigned = FactoryBot.create(:guide_edition)

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user, assigned_to_filter: "nobody").editions

      assert_equal([not_assigned], filtered_editions.to_a)
    end

    should "ignore invalid 'assigned to'" do
      anna = FactoryBot.create(:user, name: "Anna")
      # reference: note_for_postgres_migration
      FactoryBot.create(:guide_edition, assigned_to_id: anna.id)
      FactoryBot.create(:guide_edition)

      filtered_editions =
        FilteredEditionsPresenter.new(a_gds_user, assigned_to_filter: "not a valid user id").editions

      assert_equal(2, filtered_editions.count)
    end

    should "filter by format" do
      guide = FactoryBot.create(:guide_edition)
      FactoryBot.create(:completed_transaction_edition)

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user, content_type_filter: "guide").editions

      assert_equal([guide], filtered_editions.to_a)
    end

    should "return all formats when specified by the format filter" do
      FactoryBot.create(:guide_edition)
      FactoryBot.create(:completed_transaction_edition)

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user, content_type_filter: "all").editions

      assert_equal(2, filtered_editions.count)
    end

    should "search by a case-insensitively, partially-matching title" do
      guide_fawkes = FactoryBot.create(:guide_edition, title: "Guide Fawkes")
      FactoryBot.create(:guide_edition, title: "Hitchhiker's Guide")

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user, search_text: "fawkes").editions

      assert_equal([guide_fawkes], filtered_editions.to_a)
    end

    should "search by a case-insensitively, partially-matching slug" do
      guide_fawkes = FactoryBot.create(:guide_edition, title: "A non-matching title", slug: "guide-fawkes")
      FactoryBot.create(:guide_edition, title: "Another non-matching title", slug: "hitchhikers-guide")

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user, search_text: "fawkes").editions

      assert_equal([guide_fawkes], filtered_editions.to_a)
    end

    context "when 'restrict_access_by_org' feature toggle is enabled" do
      setup do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:restrict_access_by_org, true)
      end

      teardown do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:restrict_access_by_org, false)
      end

      should "filter out editions not accessible to the user" do
        user = FactoryBot.create(:user, :departmental_editor, organisation_content_id: "an-org")
        FactoryBot.create(:guide_edition, owning_org_content_ids: %w[another-org])

        filtered_editions = FilteredEditionsPresenter.new(user).editions

        assert_equal(0, filtered_editions.count)
      end
    end

    should "not return popular links" do
      guide_fawkes = FactoryBot.create(:guide_edition)
      FactoryBot.create(:popular_links)

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user).editions

      assert_equal([guide_fawkes], filtered_editions.to_a)
    end

    should "return a single 'page' of results when no page number is specified" do
      FactoryBot.create_list(:guide_edition, FilteredEditionsPresenter::ITEMS_PER_PAGE + 1)

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user).editions

      assert_equal(FilteredEditionsPresenter::ITEMS_PER_PAGE + 1, filtered_editions.count)
      assert_equal(FilteredEditionsPresenter::ITEMS_PER_PAGE, filtered_editions.to_a.count)
    end

    should "return the specified 'page' of results" do
      FactoryBot.create_list(:guide_edition, FilteredEditionsPresenter::ITEMS_PER_PAGE + 1)

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user, page: 2).editions

      assert_equal(1, filtered_editions.to_a.count)
    end

    should "order the returned results by 'updated_at' in descending order" do
      oldest = FactoryBot.create(:guide_edition, updated_at: Time.utc(2022, 1))
      newest = FactoryBot.create(:guide_edition, updated_at: Time.utc(2024, 1))
      middle = FactoryBot.create(:guide_edition, updated_at: Time.utc(2023, 1))

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user).editions

      assert_equal(3, filtered_editions.count)
      assert_equal(newest, filtered_editions[0])
      assert_equal(middle, filtered_editions[1])
      assert_equal(oldest, filtered_editions[2])
    end

    should "only query the database once, regardless of how many times it is called" do
      presenter = FilteredEditionsPresenter.new(a_gds_user)
      presenter.expects(:query_editions).once.returns([])

      presenter.editions
      presenter.editions
    end
  end

  context "#assignees" do
    should "return an 'all assignees' item" do
      assignees = FilteredEditionsPresenter.new(a_gds_user).assignees

      assert_includes(assignees, { text: "All assignees", value: "" })
    end

    should "return the current user after the 'All assignees' item" do
      current_user = FactoryBot.create(:user, name: "River Tam", id: 123)
      assignees = FilteredEditionsPresenter.new(current_user).assignees

      assert_equal("#{current_user.name} (You)", assignees[1][:text])
      assert_equal(current_user.id, assignees[1][:value])
    end

    should "only return the current user once" do
      current_user = FactoryBot.create(:user, name: "River Tam", id: 123)
      bob = FactoryBot.create(:user, name: "Bob")
      assignees = FilteredEditionsPresenter.new(current_user).assignees

      assert_equal(1, assignees.count { |user| user[:text] == "#{current_user.name} (You)" })
      assert_equal(bob.name, assignees[2][:text])
      assert_not_includes assignees.map { |user| user[:text] }, current_user.name
    end

    should "return users who are not the assignee as unselected" do
      anna = FactoryBot.create(:user, name: "Anna")
      assignees = FilteredEditionsPresenter.new(a_gds_user).assignees

      assert_includes(assignees, { text: anna.name, value: anna.id })
    end

    should "return the assignee as selected (when the assignee is the current user)" do
      a_user = a_gds_user
      assignees = FilteredEditionsPresenter.new(a_user, assigned_to_filter: a_user.id.to_s).assignees

      assert_includes(assignees, { text: "#{a_user.name} (You)", value: a_user.id, selected: "true" })
    end

    should "return the assignee as selected (when the assignee is not the current user)" do
      anna = FactoryBot.create(:user, name: "Anna")
      assignees = FilteredEditionsPresenter.new(a_gds_user, assigned_to_filter: anna.id.to_s).assignees

      assert_includes(assignees, { text: anna.name, value: anna.id, selected: "true" })
    end

    should "return users in alphabetical order" do
      bob = FactoryBot.create(:user, name: "Bob")
      charlie = FactoryBot.create(:user, name: "Charlie")
      anna = FactoryBot.create(:user, name: "Anna")

      assignees = FilteredEditionsPresenter.new(a_gds_user).assignees

      # First two items are 'All assignees' and the current user
      assert_equal(anna.name, assignees[2][:text])
      assert_equal(bob.name, assignees[3][:text])
      assert_equal(charlie.name, assignees[4][:text])
    end

    should "not include disabled users" do
      disabled_user = FactoryBot.create(:user, name: "disabled user", disabled: true)
      a_user = a_gds_user

      users = FilteredEditionsPresenter.new(a_user).assignees

      assert_equal(2, users.count)
      assert_equal("All assignees", users[0][:text])
      assert_not_includes users.map { |user| user[:text] }, disabled_user.name
    end
  end

  def note_for_postgres_migration
    # Temp-to-be-brought-back:
    # Currently we are using assigned_to_id as a field to store the assigned_to_id
    # to bypass the issue of having a belongs_to between a postgres table and a mongo table
    # we will most likely bring back the belongs_to relationship once we move edition table to postgres.
  end
end
