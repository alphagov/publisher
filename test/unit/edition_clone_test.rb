require "test_helper"

class EditionCloneTest < ActiveSupport::TestCase
  def setup
    @user = User.create :name => "Grandmaster Flash"
    @other_user = User.create :name => "Furious Five"

    @artefact = FactoryGirl.create(:artefact, name: "Childcare", slug: "childcare")
  end

  test "should clone a published GuideEdition to an AnswerEdition" do
    stub_register_published_content

    guide_edition = FactoryGirl.create(:guide_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
    guide_edition.save

    @user.start_work(guide_edition)
    @user.request_review(guide_edition,{comment: "Review this guide please."})
    @other_user.approve_review(guide_edition, {comment: "I've reviewed it"})
    @user.send_fact_check(guide_edition,{comment: "Review this guide please.", email_addresses: 'test@test.com'})
    @user.receive_fact_check(guide_edition, {comment: "No changes needed, this is all correct"})
    @other_user.approve_fact_check(guide_edition, {comment: "Looks good to me"})
    @user.publish(guide_edition, {comment: "First edition"})

    answer_edition = guide_edition.build_clone(AnswerEdition)
    answer_edition.save!

    assert_equal GuideEdition, guide_edition.class
    assert_equal AnswerEdition, answer_edition.class

    assert_equal guide_edition.title, answer_edition.title
  end

  test "should be able to switch from an AnswerEdition to a GuideEdition" do
    stub_register_published_content

    answer_edition = FactoryGirl.create(:answer_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
    answer_edition.save

    @user.start_work(answer_edition)
    @user.request_review(answer_edition,{comment: "Review this guide please."})
    @other_user.approve_review(answer_edition, {comment: "I've reviewed it"})
    @user.send_fact_check(answer_edition,{comment: "Review this guide please.", email_addresses: 'test@test.com'})
    @user.receive_fact_check(answer_edition, {comment: "No changes needed, this is all correct"})
    @other_user.approve_fact_check(answer_edition, {comment: "Looks good to me"})
    @user.publish(answer_edition, {comment: "First edition"})

    guide_edition = answer_edition.build_clone(GuideEdition)
    guide_edition.save!

    assert_equal AnswerEdition, answer_edition.class
    assert_equal GuideEdition, guide_edition.class

    assert_equal guide_edition.title, answer_edition.title
  end
end
