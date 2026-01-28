require "test_helper"

class FilteredEditionsPresenterTest < ActiveSupport::TestCase
  def a_gds_user
    FactoryBot.create(:user, organisation_content_id: PublishService::GDS_ORGANISATION_ID)
  end

  context "#content_type_options" do
    should "return content type options with 'All types' selected when no content type filter has been specified" do
      content_types_options = FilteredEditionsPresenter.new(a_gds_user).content_type_options

      assert_equal(9, content_types_options.count)
      assert_includes(content_types_options, { text: "All types", value: "", selected: true })
      assert_includes(content_types_options, { text: "Answer", value: "answer", selected: false })
      assert_includes(content_types_options, { text: "Completed transaction", value: "completed_transaction", selected: false })
      assert_includes(content_types_options, { text: "Guide", value: "guide", selected: false })
      assert_includes(content_types_options, { text: "Help page", value: "help_page", selected: false })
      assert_includes(content_types_options, { text: "Local transaction", value: "local_transaction", selected: false })
      assert_includes(content_types_options, { text: "Place", value: "place", selected: false })
      assert_includes(content_types_options, { text: "Simple smart answer", value: "simple_smart_answer", selected: false })
      assert_includes(content_types_options, { text: "Transaction", value: "transaction", selected: false })
    end

    should "mark the relevant content type option as selected when a content type filter has been specified" do
      content_types_options = FilteredEditionsPresenter.new(a_gds_user, content_type_filter: "answer").content_type_options

      assert_includes(content_types_options, { text: "Answer", value: "answer", selected: true })
      assert_includes(content_types_options, { text: "Place", value: "place", selected: false }) # Not selected
    end
  end

  context "#state_options" do
    [[true, "In 2i", "Fact check sent"], [false, "In review", "Out for fact check"]].each do |toggle_value, in_review_state_label, fact_check_state_label|
      context "when the 'rename_edition_states' feature toggle is '#{toggle_value}'" do
        setup do
          test_strategy = Flipflop::FeatureSet.current.test!
          test_strategy.switch!(:rename_edition_states, toggle_value)
        end

        should "return all state options with 'Active statuses' selected when no state filter has been specified" do
          state_options = FilteredEditionsPresenter.new(a_gds_user).state_options

          assert_equal(10, state_options.count)
          assert_includes(state_options, { text: "Active statuses", value: "", selected: true })
          assert_includes(state_options, { text: "Draft", value: :draft, selected: false })
          assert_includes(state_options, { text: in_review_state_label, value: :in_review, selected: false })
          assert_includes(state_options, { text: "Amends needed", value: :amends_needed, selected: false })
          assert_includes(state_options, { text: fact_check_state_label, value: :fact_check, selected: false })
          assert_includes(state_options, { text: "Fact check received", value: :fact_check_received, selected: false })
          assert_includes(state_options, { text: "Ready", value: :ready, selected: false })
          assert_includes(state_options, { text: "Scheduled", value: :scheduled_for_publishing, selected: false })
          assert_includes(state_options, { text: "Published", value: :published, selected: false })
          assert_includes(state_options, { text: "Archived", value: :archived, selected: false })
        end

        should "mark the relevant state as selected when a state filter has been specified" do
          state_options = FilteredEditionsPresenter.new(a_gds_user, states_filter: %w[in_review]).state_options

          assert_includes(state_options, { text: in_review_state_label, value: :in_review, selected: true })
          assert_includes(state_options, { text: "Published", value: :published, selected: false }) # Not selected
        end
      end
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
      assigned_to_anna = FactoryBot.create(:guide_edition, assigned_to: anna)
      FactoryBot.create(:guide_edition)

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user, assigned_to_filter: anna.id).editions

      assert_equal([assigned_to_anna], filtered_editions.to_a)
    end

    should "ignore invalid 'assigned to'" do
      anna = FactoryBot.create(:user, name: "Anna")
      FactoryBot.create(:guide_edition, assigned_to: anna)
      FactoryBot.create(:guide_edition)

      filtered_editions =
        FilteredEditionsPresenter.new(a_gds_user, assigned_to_filter: "not a valid user id").editions

      assert_equal(2, filtered_editions.count)
    end

    should "filter by content type" do
      guide = FactoryBot.create(:guide_edition)
      FactoryBot.create(:completed_transaction_edition)

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user, content_type_filter: "guide").editions

      assert_equal([guide], filtered_editions.to_a)
    end

    should "return all content type when no content type filter" do
      FactoryBot.create(:guide_edition)
      FactoryBot.create(:completed_transaction_edition)

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user).editions

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

    should "not paginate results by default" do
      FactoryBot.create_list(:guide_edition, FilteredEditionsPresenter::ITEMS_PER_PAGE + 1)

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user).editions

      assert_equal(FilteredEditionsPresenter::ITEMS_PER_PAGE + 1, filtered_editions.count)
    end

    should "return a single 'page' of results when no page number is specified" do
      FactoryBot.create_list(:guide_edition, FilteredEditionsPresenter::ITEMS_PER_PAGE + 1)

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user, paginate: true).editions

      assert_equal(FilteredEditionsPresenter::ITEMS_PER_PAGE, filtered_editions.count)
    end

    should "make the total number of editions available when there's more than one page of results" do
      FactoryBot.create_list(:guide_edition, FilteredEditionsPresenter::ITEMS_PER_PAGE + 1)

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user, paginate: true).editions

      assert_equal(FilteredEditionsPresenter::ITEMS_PER_PAGE + 1, filtered_editions.total_count)
    end

    should "return the specified 'page' of results" do
      FactoryBot.create_list(:guide_edition, FilteredEditionsPresenter::ITEMS_PER_PAGE + 1)

      filtered_editions = FilteredEditionsPresenter.new(a_gds_user, paginate: true, page: 2).editions

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

  context "#assignee_options" do
    should "return an 'all assignees' item" do
      assignee_options = FilteredEditionsPresenter.new(a_gds_user).assignee_options

      assert_includes(assignee_options, { text: "All assignees", value: "", selected: true })
    end

    should "return the current user after the 'All assignees' item" do
      current_user = FactoryBot.create(:user, name: "River Tam", id: 123)
      assignee_options = FilteredEditionsPresenter.new(current_user).assignee_options

      assert_equal("#{current_user.name} (You)", assignee_options[1][:text])
      assert_equal(current_user.id, assignee_options[1][:value])
    end

    should "only return the current user once" do
      current_user = FactoryBot.create(:user, name: "River Tam", id: 123)
      bob = FactoryBot.create(:user, name: "Bob")
      assignee_options = FilteredEditionsPresenter.new(current_user).assignee_options

      assert_equal(1, assignee_options.count { |user| user[:text] == "#{current_user.name} (You)" })
      assert_equal(bob.name, assignee_options[2][:text])
      assert_not_includes assignee_options.map { |user| user[:text] }, current_user.name
    end

    should "return users who are not the assignee as unselected" do
      anna = FactoryBot.create(:user, name: "Anna")
      assignee_options = FilteredEditionsPresenter.new(a_gds_user).assignee_options

      assert_includes(assignee_options, { text: anna.name, value: anna.id, selected: false })
    end

    should "return the assignee as selected (when the assignee is the current user)" do
      a_user = a_gds_user
      assignee_options = FilteredEditionsPresenter.new(a_user, assigned_to_filter: a_user.id.to_s).assignee_options

      assert_includes(assignee_options, { text: "#{a_user.name} (You)", value: a_user.id, selected: true })
    end

    should "return the assignee as selected (when the assignee is not the current user)" do
      anna = FactoryBot.create(:user, name: "Anna")
      assignee_options = FilteredEditionsPresenter.new(a_gds_user, assigned_to_filter: anna.id.to_s).assignee_options

      assert_includes(assignee_options, { text: anna.name, value: anna.id, selected: true })
    end

    should "return users in alphabetical order" do
      bob = FactoryBot.create(:user, name: "Bob")
      charlie = FactoryBot.create(:user, name: "Charlie")
      anna = FactoryBot.create(:user, name: "Anna")

      assignee_options = FilteredEditionsPresenter.new(a_gds_user).assignee_options

      # First two items are 'All assignees' and the current user
      assert_equal(anna.name, assignee_options[2][:text])
      assert_equal(bob.name, assignee_options[3][:text])
      assert_equal(charlie.name, assignee_options[4][:text])
    end

    should "not include disabled users" do
      disabled_user = FactoryBot.create(:user, name: "disabled user", disabled: true)
      a_user = a_gds_user

      assignee_options = FilteredEditionsPresenter.new(a_user).assignee_options

      assert_equal(2, assignee_options.count)
      assert_equal("All assignees", assignee_options[0][:text])
      assert_not_includes assignee_options.map { |user| user[:text] }, disabled_user.name
    end
  end
end
