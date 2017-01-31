require 'test_helper'
require 'gds_api/test_helpers/content_store'

class SyncCheckerTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::ContentStore

  context "#call" do
    setup do
      edition = stub(
        slug: "help/cookies",
        schema_name: "help_page",
      )
      @scope = [edition]
      @sync_checker = SyncChecker.new(@scope, "content-store")
    end

    context "for content present in content store" do
      setup do
        content_store_has_item("/help/cookies", schema_name: "help_page")
      end

      should 'succeed for matching expectation' do
        SyncChecker::Success.stubs(new: stub(to_s: "yay"))
        SyncChecker::Success.expects(:new).once

        @sync_checker.add_expectation("schema_name") do |content_item, _|
          content_item["schema_name"] == "help_page"
        end

        @sync_checker.call
      end

      should 'fail for non-matching expectation' do
        SyncChecker::Failure.stubs(new: stub(to_s: "boo"))
        SyncChecker::Failure.expects(:new).once

        @sync_checker.add_expectation("schema_name") do |content_item, _|
          content_item["schema_name"] == "other_format"
        end

        @sync_checker.call
      end
    end

    context "for content missing in content store" do
      setup do
        content_store_does_not_have_item("/help/cookies")
      end

      should 'fail' do
        SyncChecker::NotFoundFailure.stubs(new: stub(to_s: "not found"))
        SyncChecker::NotFoundFailure.expects(:new).once

        @sync_checker.call
      end
    end
  end
end
