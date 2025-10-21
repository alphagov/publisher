require "test_helper"

class EditionCloneTest < ActiveSupport::TestCase
  def setup
    @user = FactoryBot.create(:user, :govuk_editor, uid: "123", name: "Grandmaster Flash")
    @other_user = FactoryBot.create(:user, :govuk_editor, uid: "321", name: "Furious Five")

    @artefact = FactoryBot.create(:artefact, name: "Childcare", slug: "childcare")
    stub_calendars_has_no_bank_holidays(in_division: "england-and-wales")
  end

  def fact_check_and_publish(edition = nil)
    request_review(@user, edition)
    approve_review(@other_user, edition)
    send_fact_check(@user, edition)
    receive_fact_check(@user, edition)
    approve_fact_check(@user, edition)
    publish(@user, edition)
  end

  test "should clone a published GuideEdition to an AnswerEdition" do
    stub_register_published_content

    guide_edition = FactoryBot.create(:guide_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
    guide_edition.save!

    fact_check_and_publish(guide_edition)

    answer_edition = guide_edition.build_clone(AnswerEdition)

    assert_equal GuideEdition, guide_edition.editionable.class
    assert_equal AnswerEdition, answer_edition.editionable.class

    assert_equal guide_edition.title, answer_edition.title
  end

  test "should be able to switch from an AnswerEdition to a GuideEdition" do
    stub_register_published_content

    answer_edition = FactoryBot.create(:answer_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
    answer_edition.save!

    fact_check_and_publish(answer_edition)

    guide_edition = answer_edition.build_clone(GuideEdition)

    assert_equal AnswerEdition, answer_edition.editionable.class
    assert_equal GuideEdition, guide_edition.editionable.class

    assert_equal guide_edition.title, answer_edition.title
  end

  test "should convert GuideEdition with parts into an AnswerEdition" do
    stub_register_published_content

    edition = FactoryBot.create(:guide_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
    edition.parts.build(title: "Some Part Title!", body: "This is some **version** text.", slug: "part-one")
    edition.parts.build(title: "Another Part Title", body: "This is [link](http://example.net/) text.", slug: "part-two")
    edition.save!

    fact_check_and_publish(edition)

    cloned_edition = edition.build_clone(AnswerEdition)

    assert_equal GuideEdition, edition.editionable.class
    assert_equal AnswerEdition, cloned_edition.editionable.class

    assert_equal "# Some Part Title!\n\nThis is some **version** text.\n\n# Another Part Title\n\nThis is [link](http://example.net/) text.", edition.whole_body
    assert_equal edition.whole_body, cloned_edition.whole_body
    assert_equal edition.title, cloned_edition.title
  end

  test "should convert AnswerEdition into a GuideEdition" do
    stub_register_published_content

    answer_edition = FactoryBot.create(:answer_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
    answer_edition.body = "Bleep, bloop, blop"
    answer_edition.save!

    fact_check_and_publish(answer_edition)

    guide_edition = answer_edition.build_clone(GuideEdition)
    guide_edition.save!

    assert_equal AnswerEdition, answer_edition.editionable.class
    assert_equal GuideEdition, guide_edition.editionable.class

    assert_equal "# Part One\n\nBleep, bloop, blop", guide_edition.whole_body
    assert_equal guide_edition.title, answer_edition.title
  end
end
