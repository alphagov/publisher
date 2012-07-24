require "test_helper"

class EditionCloneTest < ActiveSupport::TestCase
  def setup
    @user = User.create :name => "Grandmaster Flash"
    @other_user = User.create :name => "Furious Five"

    @artefact = FactoryGirl.create(:artefact, name: "Childcare", slug: "childcare")
  end

  def fact_check_and_publish(edition = nil)
    @user.start_work(edition)
    @user.request_review(edition, {comment: "Review this guide please."})
    @other_user.approve_review(edition, {comment: "I've reviewed it"})
    @user.send_fact_check(edition, {comment: "Review this guide please.", email_addresses: 'test@test.com'})
    @user.receive_fact_check(edition, {comment: "No changes needed, this is all correct"})
    @other_user.approve_fact_check(edition, {comment: "Looks good to me"})
    @user.publish(edition, {comment: "First edition"})
  end

  test "should clone a published GuideEdition to an AnswerEdition" do
    stub_register_published_content

    guide_edition = FactoryGirl.create(:guide_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
    guide_edition.save

    fact_check_and_publish(guide_edition)

    answer_edition = guide_edition.build_clone(AnswerEdition)

    assert_equal GuideEdition, guide_edition.class
    assert_equal AnswerEdition, answer_edition.class

    assert_equal guide_edition.title, answer_edition.title
  end

  test "should be able to switch from an AnswerEdition to a GuideEdition" do
    stub_register_published_content

    answer_edition = FactoryGirl.create(:answer_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
    answer_edition.save

    fact_check_and_publish(answer_edition)

    guide_edition = answer_edition.build_clone(GuideEdition)

    assert_equal AnswerEdition, answer_edition.class
    assert_equal GuideEdition, guide_edition.class

    assert_equal guide_edition.title, answer_edition.title
  end

  test "should convert GuideEdition with parts into an AnswerEdition" do
    stub_register_published_content

    guide_edition = FactoryGirl.create(:guide_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
    guide_edition.parts.build(title: "Some Part Title!", body: "This is some **version** text.", slug: "part-one")
    guide_edition.parts.build(title: "Another Part Title", body: "This is [link](http://example.net/) text.", slug: "part-two")
    guide_edition.save

    fact_check_and_publish(guide_edition)

    answer_edition = guide_edition.build_clone(AnswerEdition)

    assert_equal GuideEdition, guide_edition.class
    assert_equal AnswerEdition, answer_edition.class

    assert_equal "# Some Part Title!\n\nThis is some **version** text.\n\n# Another Part Title\n\nThis is [link](http://example.net/) text.", guide_edition.whole_body
    assert_equal guide_edition.whole_body, answer_edition.whole_body
    assert_equal guide_edition.title, answer_edition.title
  end

  test "should convert AnswerEdition into a GuideEdition" do
    stub_register_published_content

    answer_edition = FactoryGirl.create(:answer_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
    answer_edition.body = "Bleep, bloop, blop"
    answer_edition.save

    fact_check_and_publish(answer_edition)

    guide_edition = answer_edition.build_clone(GuideEdition)

    assert_equal AnswerEdition, answer_edition.class
    assert_equal GuideEdition, guide_edition.class

    assert_equal "# Part One\n\nBleep, bloop, blop", guide_edition.whole_body
    assert_equal guide_edition.title, answer_edition.title
  end
end
