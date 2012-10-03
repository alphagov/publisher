require 'test_helper'
require 'benefits_links_migrator'

class BenefitsLinksMigratorTest < ActiveSupport::TestCase
  context "replace_anchors" do
    setup do
      body = '
        ### Foo bar
        
        % Do something now, NOW! %

        More text here lets have a link to a benefit process page [here] (/super-benefit#what-youll-get "What you will get") 
        then a bit more waffle, and how about [another link] (/another-thing#overview "Overview") then we will talk some more 
        about things, important things that we [link to] (/somewhere-else#eligibility) and then we have an anchored link which 
        should [not] (/should-not-change#no-it-should-not) change.
      '
      @user = FactoryGirl.create(:user)
      @answer = FactoryGirl.create(:answer_edition, body: body)
      @programme = FactoryGirl.create(:programme_edition)
      @published_programme = FactoryGirl.create(:programme_edition, state: 'published')
      @programme.parts.first.body = body
      @published_programme.parts.first.body = body
      @programme.save!
      @published_programme.save!
      silence_stream(STDOUT) do     
        BenefitsLinksMigrator.new.replace_anchors(@user.name)
      end
      @answer.reload
      @programme.reload
    end
    should "replace specific anchors on urls with the relevant path segment in Editions with a body" do
      assert_match "/another-thing/overview", @answer.body
      assert_match "/super-benefit/what-youll-get", @answer.body
      assert_match "/should-not-change#no-it-should-not", @answer.body
    end
    should "replace specific anchors on urls with the relevant path segment in Editions with parts" do
      assert_match "/another-thing/overview", @programme.parts.first.body
      assert_match "/super-benefit/what-youll-get", @programme.parts.first.body
      assert_match "/should-not-change#no-it-should-not", @programme.parts.first.body
    end
    should "create a new revision for published editions and give them in_review state" do
      new_edition = Edition.last
      assert_match "/another-thing/overview", new_edition.parts.first.body 
      assert_equal 'request_review', new_edition.actions.first.request_type
      assert_equal 'in_review', new_edition.state
    end
  end
end
