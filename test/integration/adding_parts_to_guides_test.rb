require 'integration_test_helper'

class AddingPartsToGuidesTest < JavascriptIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
  end

  context 'creating a guide with parts' do
    setup do
      @random_name = (0...8).map { 65.+(rand(25)).chr }.join + " GUIDE"

      guide = FactoryBot.create(:guide_edition, title: @random_name, slug: 'test-guide')
      guide.save!
      guide.update_attribute(:state, 'draft')

      visit_edition guide

      add_new_part
      within :css, '#parts div.fields:first-of-type' do
        fill_in 'Title', with: 'Part One'
        fill_in 'Body',  with: 'Body text'
        fill_in 'Slug',  with: 'part-one'
      end

      assert page.has_css?('#parts div.fields', count: 1)

      add_new_part
      within :css, '#parts div.fields:nth-of-type(2)' do
        fill_in 'Title', with: 'Part Two'
        fill_in 'Body',  with: 'Body text'
        fill_in 'Slug',  with: 'part-two'
      end

      assert page.has_css?('#parts div.fields', count: 2)

      add_new_part
      within :css, '#parts div.fields:nth-of-type(3)' do
        fill_in 'Title', with: 'Part Three'
        fill_in 'Body',  with: 'Body text'
        fill_in 'Slug',  with: 'part-three'
      end
    end

    should "save the guide and parts using ajax" do
      save_edition_and_assert_success
      assert_correct_parts
      visit current_path
      assert_correct_parts

      visit "/?user_filter=all&list=drafts"
      assert page.has_content? @random_name
    end

    should "be able to hide and show edited part after saving" do
      save_edition_and_assert_success
      assert page.has_css?('#part-one[aria-expanded="true"]')
      within :css, '#parts div.fields:nth-of-type(1)' do
        fill_in 'Title', with: 'Part One (edited)'
        fill_in 'Body',  with: 'Body text'
        fill_in 'Slug',  with: 'part-one-edited'
      end
      save_edition_and_assert_success

      assert page.has_css?('#part-one-edited[aria-expanded="true"]')

      # collapse part
      click_on 'Part One (edited)'
      assert page.has_css?('#part-one-edited[aria-expanded="false"]')
    end

    should "add the new parts only once" do
      save_edition_and_assert_success
      save_edition_and_assert_success
      save_edition_and_assert_success
      assert_correct_parts

      visit current_path
      assert_correct_parts

      save_edition_and_assert_success
      save_edition_and_assert_success
      assert_correct_parts

      visit current_path
      assert_correct_parts
    end

    context 'removing parts' do
      setup do
        save_edition_and_assert_success
        visit current_path
      end

      should 'remove the appropriate part' do
        within :css, '#parts div.fields:nth-of-type(3)' do
          click_on 'Remove this part'
        end

        save_edition_and_assert_success
        assert_correct_parts(2)

        visit current_path
        assert_correct_parts(2)

        within :css, '#parts div.fields:nth-of-type(2)' do
          click_on 'Remove this part'
        end

        save_edition_and_assert_success
        assert_correct_parts(1)

        visit current_path
        assert_correct_parts(1)
      end
    end

    context 'when removing parts' do
      setup do
        save_edition_and_assert_success
        visit current_path
      end

      should 'remove the appropriate part' do
        within :css, '#parts div.fields:nth-of-type(3)' do
          click_on 'Remove this part'
        end

        save_edition_and_assert_success
        assert_correct_parts(2)

        visit current_path
        assert_correct_parts(2)

        within :css, '#parts div.fields:nth-of-type(2)' do
          click_on 'Remove this part'
        end

        save_edition_and_assert_success
        assert_correct_parts(1)

        visit current_path
        assert_correct_parts(1)
      end
    end

    context 'when entering invalid parts' do
      setup do
        save_edition_and_assert_success
        visit current_path
      end

      should 'not save when a part is invalid' do
        within :css, '#parts div.fields:nth-of-type(2)' do
          fill_in 'Slug',  with: ''
        end

        within :css, '#parts div.fields:nth-of-type(3)' do
          fill_in 'Title', with: ''
          fill_in 'Slug', with: 'part-three'
        end

        save_edition_and_assert_error

        assert page.has_css?('#parts .has-error', count: 2)

        within :css, '#parts div.fields:nth-of-type(2)' do
          assert page.has_css?('.has-error[id*="slug"]')
          assert page.has_css?('.js-error li', count: 2)
          assert page.has_css?('.js-error li', text: 'can\'t be blank')
          assert page.has_css?('.js-error li', text: 'is invalid')
        end

        within :css, '#parts div.fields:nth-of-type(3)' do
          assert page.has_css?('.has-error[id*="title"]')
          assert page.has_css?('.js-error li', count: 1)
          assert page.has_css?('.js-error li', text: 'can\'t be blank')
        end
      end
    end
  end

  test "slug for new parts should be automatically generated" do
    random_name = (0...8).map { 65.+(rand(25)).chr }.join + " GUIDE"

    guide = FactoryBot.create(:guide_edition, title: random_name, slug: 'test-guide')
    guide.save!
    guide.update_attribute(:state, 'draft')

    visit_edition guide

    add_new_part
    within :css, '#parts .fields:first-of-type .part' do
      fill_in 'Title', with: 'Part One'
      fill_in 'Body',  with: 'Body text'
      assert_equal 'part-one', find(:css, ".slug").value

      fill_in 'Title', with: 'Part One changed'
      fill_in 'Body',  with: 'Body text'
      assert_equal 'part-one-changed', find(:css, ".slug").value
    end
  end

  test "slug for edition which has been previously published shouldn't be generated" do
    guide = FactoryBot.create(:guide_edition_with_two_parts, state: 'published', title: "Foo bar")
    guide.save!
    visit_edition guide
    click_on "Create new edition"

    within :css, '#parts .fields:first-of-type .part' do
      assert_equal 'part-one', find(:css, ".slug").value
      fill_in 'Title', with: 'Part One changed'
      fill_in 'Body',  with: 'Body text'
      assert_equal 'part-one', find(:css, ".slug").value
    end
  end

  def assert_correct_parts(count = 3)
    assert page.has_css?('#parts .panel-part', count: count)
    assert page.has_css?('#parts .panel-title', count: count)
    assert page.has_css?('#parts .panel-body', count: count)

    if count > 0
      assert page.has_css?('#part-one', count: 1)
      assert_equal page.find('#part-one input.title').value, 'Part One'
    end

    if count > 1
      assert page.has_css?('#part-two', count: 1)
      assert_equal page.find('#part-two input.title').value, 'Part Two'
    end

    if count > 2
      assert page.has_css?('#part-three', count: 1)
      assert_equal page.find('#part-three input.title').value, 'Part Three'
    end
  end
end
