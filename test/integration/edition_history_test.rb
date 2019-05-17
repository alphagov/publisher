require 'integration_test_helper'

class EditionHistoryTest < JavascriptIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
  end

  context "viewing the history and notes tab" do
    setup do
      @answer = FactoryBot.create(:answer_edition, state: "published", slug: "test-slug")

      @answer.new_action(@author, Action::SEND_FACT_CHECK, comment: "first", email_addresses: 'a@a.com, b@b.com')
      @answer.new_action(@author, Action::RECEIVE_FACT_CHECK, comment: "second")
      @answer.new_action(@author, Action::PUBLISH, comment: "third")

      assert_equal %w(first second third), @answer.actions.map(&:comment)

      @guide = @answer.build_clone(GuideEdition)
      @guide.save

      @guide.new_action(@author, Action::SEND_FACT_CHECK, comment: "fourth")
      @guide.new_action(@author, Action::RECEIVE_FACT_CHECK, comment: "fifth")
      @guide.new_action(@author, Action::PUBLISH, comment: "sixth")
      @guide.new_action(@author, Action::NOTE, comment: "link http://www.some-link.com")

      assert_equal ["fourth", "fifth", "sixth", "link http://www.some-link.com"], @guide.actions.map(&:comment)
    end

    should "direct the user to view a published edition on GOV.UK directly, not draft" do
      visit_edition @answer
      click_on "History and notes"

      assert page.has_css?('#edition-history p.add-bottom-margin', text: "View this on the GOV.UK website")
      assert page.has_link?("/test-slug", href: "#{Plek.new.website_root}/#{@answer.slug}")
    end

    should "not show the view link for archived editions" do
      @answer.update_attribute(:state, 'archived')

      visit_edition @answer
      click_on "History and notes"

      assert page.has_no_css?('#edition-history p.add-bottom-margin', text: "Preview edition at")
      assert page.has_no_css?('#edition-history p.add-bottom-margin', text: "View this on the GOV.UK website")
    end

    should "have the first history actions visible" do
      visit_edition @guide
      click_on "History and notes"

      assert page.has_css?('#edition-history div.panel:first-of-type div.panel-collapse.in')
    end

    should "have clickable links in notes" do
      visit_edition @guide
      click_on "History and notes"

      assert page.has_css?('.panel a[href="http://www.some-link.com"]', text: 'http://www.some-link.com')
    end

    should "hide everything but the latest reply in fact check responses behind a toggle" do
      @guide.new_action(@author, Action::RECEIVE_FACT_CHECK, comment: "email reply\n-----Original Message-----\noriginal email request")

      visit_edition @guide
      click_on "History and notes"

      assert page.has_css?('p', text: 'email reply')
      assert page.has_no_css?('p', text: 'original email request')
      assert page.has_css?('.panel a', text: 'Toggle earlier messages')

      click_on "Toggle earlier messages"

      assert page.has_css?('p', text: 'original email request')
    end

    should "include the email addresses of fact check request recipients" do
      visit_edition @guide
      click_on "History and notes"
      click_on "Edition 1"
      assert page.has_css?('p', text: "first")
      assert page.has_css?('p', text: "Request sent to a@a.com, b@b.com")
      assert page.has_css?('.panel a[href="mailto:a@a.com%2Cb@b.com"]', text: 'a@a.com, b@b.com')
    end

    should "hide actions when the edition title is clicked" do
      visit_edition @guide
      click_on "History and notes"
      click_on "Edition 2"
      assert page.has_no_css?('#edition-history div.panel:first-of-type div.panel-collapse.in')
    end

    context "Important note" do
      should "be able to add and resolve a note" do
        add_important_note("This is an important note. Take note.")

        visit_edition @guide
        assert page.has_content? "This is an important note. Take note."
        assert page.has_css?('.callout-important-note')

        click_on "History and notes"
        click_on "Delete important note"
        visit_edition @guide
        assert page.has_no_css?('.callout-important-note')
      end

      should "prepopulate with an existing note" do
        add_important_note("This is an important note. Take note.")

        visit_edition @guide
        click_on "History and notes"
        click_on "Update important note"

        within "#update-important-note" do
          assert_field_contains("This is an important note. Take note.", "Important note")
        end
      end

      should "resolve an important note if an empty one is saved" do
        add_important_note("Note")
        add_important_note("")

        assert page.has_no_css?('.callout-important-note')
      end

      should "have clickable links and zendesk tickets" do
        add_important_note("Note http://www.google.com zen 123456")
        assert page.has_css?('.callout-important-note .callout-body a', count: 2)
      end

      should "not be carried forward to new editions" do
        @edition = FactoryBot.create(:answer_edition,
                                     state: "published")
        @edition.actions.create(request_type: Action::IMPORTANT_NOTE,
                                comment: "This is an important note. Take note.")

        visit_edition @edition
        assert page.has_content? "This is an important note. Take note."

        click_on "Create new edition"
        assert page.has_no_content? "This is an important note. Take note."

        click_on "History and notes"
        click_on "Update important note"
        within "#update-important-note" do
          assert_field_contains("", "Important note")
        end
      end

      should "not show important notes in edition history" do
        add_important_note("Note")
        add_important_note("")
        add_important_note("Another note")

        assert page.has_no_css?('.action-important-note')
        assert page.has_no_css?('.action-important-note-resolved')
      end

      should "shows a history of important notes behind a toggle when there are modifications" do
        add_important_note("First note")
        assert page.has_content?('Note created')

        add_important_note("An updated note")
        assert page.has_content?('Note updated')
        assert page.has_no_css?('.callout-important-note table')

        click_on "See history"
        assert page.has_css?('.callout-important-note table tbody tr', count: 2)
        assert page.has_css?('.callout-important-note tr:last-child td', text: 'First note')
        assert page.has_css?('.callout-important-note tr:first-child td', text: 'An updated note')
      end
    end
  end

  def add_important_note(note)
    visit_edition @guide
    click_on "History and notes"
    click_on "Update important note"

    within "#update-important-note" do
      fill_in "Important note", with: note
      click_on "Save important note"
    end
  end
end
