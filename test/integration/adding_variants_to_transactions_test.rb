require "integration_test_helper"

class AddingVariantsToTransactionsTest < JavascriptIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
  end

  context "creating a transaction with variants" do
    setup do
      @random_name = (0...8).map { rand(65..89).chr }.join + " TRANSACTION"

      transaction = FactoryBot.create(:transaction_edition, title: @random_name, slug: "test-transaction")
      transaction.save!
      transaction.update(state: "draft")

      visit_edition transaction

      add_new_variant
      within :css, "#parts div.fields:first-of-type" do
        fill_in "Title", with: "Variant One"
        fill_in "Introductory paragraph", with: "Body text"
        fill_in "Slug", with: "variant-one"
        fill_in "Link to start of transaction", with: "http://www.example.com/one"
      end

      assert page.has_css?("#parts div.fields", count: 1)

      add_new_variant
      within :css, "#parts div.fields:nth-of-type(2)" do
        fill_in "Title", with: "Variant Two"
        fill_in "Introductory paragraph", with: "Body text"
        fill_in "Slug", with: "variant-two"
        fill_in "Link to start of transaction", with: "http://www.example.com/two"
      end

      assert page.has_css?("#parts div.fields", count: 2)

      add_new_variant
      within :css, "#parts div.fields:nth-of-type(3)" do
        fill_in "Title", with: "Variant Three"
        fill_in "Introductory paragraph", with: "Body text"
        fill_in "Slug", with: "variant-three"
        fill_in "Link to start of transaction", with: "http://www.example.com/three"
      end
    end

    should "save the transaction and variants using ajax" do
      save_edition_and_assert_success
      visit current_path
      assert_correct_variants

      visit "/?user_filter=all&list=drafts"
      assert page.has_content? @random_name
    end

    should "be able to hide and show edited variant after saving" do
      save_edition_and_assert_success
      visit current_path
      assert page.has_css?('#variant-one[aria-expanded="true"]')
      within :css, "#parts div.fields:nth-of-type(1)" do
        fill_in "Title", with: "Variant One (edited)"
        fill_in "Introductory paragraph", with: "Body text"
        fill_in "Slug", with: "variant-one-edited"
        fill_in "Link to start of transaction", with: "http://www.example.com/one-new"
      end
      save_edition_and_assert_success

      assert page.has_css?('#variant-one-edited[aria-expanded="true"]')

      # collapse variant
      click_on "Variant One (edited)"
      assert page.has_css?('#variant-one-edited[aria-expanded="false"]')
    end

    should "add the new variants only once" do
      save_edition_and_assert_success
      save_edition_and_assert_success
      save_edition_and_assert_success

      visit current_path
      assert_correct_variants

      save_edition_and_assert_success
      save_edition_and_assert_success
      assert_correct_variants

      visit current_path
      assert_correct_variants
    end

    context "when removing variants" do
      setup do
        save_edition_and_assert_success
        visit current_path
      end

      should "remove the appropriate variant" do
        within :css, "#parts div.fields:nth-of-type(3)" do
          click_on "Remove this variant"
        end

        save_edition_and_assert_success
        assert_correct_variants(2)

        visit current_path
        assert_correct_variants(2)

        within :css, "#parts div.fields:nth-of-type(2)" do
          click_on "Remove this variant"
        end

        save_edition_and_assert_success
        assert_correct_variants(1)

        visit current_path
        assert_correct_variants(1)
      end
    end

    context "when entering invalid variants" do
      setup do
        save_edition_and_assert_success
        visit current_path
      end

      should "not save when a variant is invalid" do
        within :css, "#parts div.fields:nth-of-type(2)" do
          fill_in "Slug", with: ""
        end

        within :css, "#parts div.fields:nth-of-type(3)" do
          fill_in "Title", with: ""
          fill_in "Slug", with: "variant-three"
        end

        save_edition_and_assert_error

        assert page.has_css?("#parts .has-error", count: 2)

        within :css, "#parts div.fields:nth-of-type(2)" do
          assert page.has_css?('.has-error[id*="slug"]')
          assert page.has_css?(".js-error li", count: 2)
          assert page.has_css?(".js-error li", text: "can't be blank")
          assert page.has_css?(".js-error li", text: "is invalid")
        end

        within :css, "#parts div.fields:nth-of-type(3)" do
          assert page.has_css?('.has-error[id*="title"]')
          assert page.has_css?(".js-error li", count: 1)
          assert page.has_css?(".js-error li", text: "can't be blank")
        end
      end
    end
  end

  test "slug for new variants should be automatically generated" do
    random_name = (0...8).map { rand(65..89).chr }.join + " TRANSACTION"

    transaction = FactoryBot.create(:transaction_edition, title: random_name, slug: "test-transaction")
    transaction.save!
    transaction.update(state: "draft")

    visit_edition transaction

    add_new_variant
    within :css, "#parts .fields:first-of-type .part" do
      fill_in "Title", with: "Variant One"
      fill_in "Introductory paragraph", with: "Body text"
      assert_equal "variant-one", find(:css, ".slug").value

      fill_in "Title", with: "Variant One changed"
      fill_in "Introductory paragraph", with: "Body text"
      assert_equal "variant-one-changed", find(:css, ".slug").value
    end
  end

  test "slug for edition which has been previously published shouldn't be generated" do
    transaction = FactoryBot.create(:transaction_edition_with_two_variants, state: "published", title: "Foo bar")
    transaction.save!
    visit_edition transaction
    click_on "Create new edition"

    within :css, "#parts .fields:first-of-type .part" do
      assert_equal "variant-one", find(:css, ".slug").value
      fill_in "Title", with: "Variant One changed"
      fill_in "Introductory paragraph", with: "Body text"
      assert_equal "variant-one", find(:css, ".slug").value
    end
  end

  def assert_correct_variants(count = 3)
    assert page.has_css?("#parts .panel-part", count: count)
    assert page.has_css?("#parts .panel-title", count: count)
    assert page.has_css?("#parts .panel-body", count: count)

    if count > 0 # rubocop:disable Style/NumericPredicate
      assert page.has_css?("#variant-one", count: 1)
      assert_equal page.find("#variant-one input.title").value, "Variant One"
    end

    if count > 1
      assert page.has_css?("#variant-two", count: 1)
      assert_equal page.find("#variant-two input.title").value, "Variant Two"
    end

    if count > 2
      assert page.has_css?("#variant-three", count: 1)
      assert_equal page.find("#variant-three input.title").value, "Variant Three"
    end
  end
end
