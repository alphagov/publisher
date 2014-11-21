require 'integration_test_helper'

class EditionHistoryTest < JavascriptIntegrationTest
  setup do
    setup_users
    stub_collections
  end

  context "viewing the history and notes tab" do
    setup do
      @answer = FactoryGirl.create(:answer_edition, :state => "published")

      @answer.new_action(@author, Action::SEND_FACT_CHECK, {:comment => "first", :email_addresses => 'a@a.com, b@b.com'})
      @answer.new_action(@author, Action::RECEIVE_FACT_CHECK, {:comment => "second"})
      @answer.new_action(@author, Action::PUBLISH, {:comment => "third"})

      assert_equal ["first", "second", "third"], @answer.actions.map(&:comment)

      @guide = @answer.build_clone(GuideEdition)

      @guide.new_action(@author, Action::SEND_FACT_CHECK, {:comment => "fourth"})
      @guide.new_action(@author, Action::RECEIVE_FACT_CHECK, {:comment => "fifth"})
      @guide.new_action(@author, Action::PUBLISH, {:comment => "sixth"})
      @guide.new_action(@author, Action::NOTE, {:comment => "link http://www.some-link.com"})

      assert_equal ["fourth", "fifth", "sixth", "link http://www.some-link.com"], @guide.actions.map(&:comment)

      @guide.new_action(@author, Action::RECEIVE_FACT_CHECK, {:comment => "email reply\n-----Original Message-----\noriginal email request"})
    end

    should "have the first history actions visible" do
      visit "/editions/#{@guide.id}"
      click_on "History and notes"

      assert page.has_css?('#edition-history div.panel:first-of-type div.panel-collapse.in')
    end

    should "have clickable links in notes" do
      visit "/editions/#{@guide.id}"
      click_on "History and notes"

      assert page.has_css?('.panel a[href="http://www.some-link.com"]', text: 'http://www.some-link.com')
    end

    should "hide everything but the latest reply in fact check responses behind a toggle" do
      visit "/editions/#{@guide.id}"
      click_on "History and notes"

      assert page.has_css?('p', text: 'email reply')
      refute page.has_css?('p', text: 'original email request')
      assert page.has_css?('.panel a', text: 'Toggle original message')

      click_on "Toggle original message"

      assert page.has_css?('p', text: 'original email request')
    end

    should "include the email addresses of fact check request recipients" do
      visit "/editions/#{@guide.id}"
      click_on "History and notes"
      click_on "Edition 1"
      assert page.has_css?('p', text: "first")
      assert page.has_css?('p', text: "Request sent to a@a.com, b@b.com")
      assert page.has_css?('.panel a[href="mailto:a@a.com,b@b.com"]', text: 'a@a.com, b@b.com')
    end

    should "hide actions when the edition title is clicked" do
      visit "/editions/#{@guide.id}"
      click_on "History and notes"
      click_on "Edition 2"
      assert page.has_no_css?('#edition-history div.panel:first-of-type div.panel-collapse.in')
    end

    context "Important note" do
      should "be able to add and resolve a note" do
        add_important_note("This is an important note. Take note.")

        visit "/editions/#{@guide.id}"
        assert page.has_content? "This is an important note. Take note."

        click_on "History and notes"
        click_on "Delete important note"
        visit "/editions/#{@guide.id}"
        assert page.has_no_css?('.important-note')
      end

      should "prepopulate with an existing note" do
        add_important_note("This is an important note. Take note.")

        visit "/editions/#{@guide.id}"
        click_on "History and notes"
        click_on "Update important note"

        within "#update-important-note" do
          assert_field_contains("This is an important note. Take note.", "Important note")
        end
      end

      should "resolve an important note if an empty one is saved" do
        add_important_note("Note")
        add_important_note("")

        assert page.has_no_css?('.important-note')
      end

      should "not be carried forward to new editions" do
        @edition = FactoryGirl.create(:answer_edition,
                                      :state => "published")
        @edition.actions.create(:request_type => Action::IMPORTANT_NOTE,
                                :comment => "This is an important note. Take note.")

        visit "/editions/#{@edition.id}"
        assert page.has_content? "This is an important note. Take note."

        click_on "Create new edition"
        assert page.has_no_content? "This is an important note. Take note."

        click_on "History and notes"
        click_on "Update important note"
        within "#update-important-note" do
          assert_field_contains("", "Important note")
        end
      end
    end
  end

  def add_important_note(note)
    visit "/editions/#{@guide.id}"
    click_on "History and notes"
    click_on "Update important note"

    within "#update-important-note" do
      fill_in "Important note", with: note
      click_on "Save important note"
    end
  end
end
