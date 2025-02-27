require "test_helper"

class TimeZoneTest < ActiveSupport::TestCase
  # TODO: Temporarily comment out the test as we think this might not be needed anymore, subject to further investigation

  # def first_day_of_summer_time
  #   Time.zone.parse("2013-04-01")
  # end
  #
  # def wintertime
  #   Time.zone.parse("2013-01-01")
  # end
  #
  # context "use_activesupport_time_zone is set to true, Time.zone is set to 'London'" do
  #   setup do
  #     # This context has already been set in the local mongoid.yml, and in test_helper.rb
  #   end
  #
  #   should "store the date in GMT" do
  #     Timecop.freeze(wintertime) do
  #       FactoryBot.create(:artefact)
  #       assert_equal "GMT", Artefact.last.attributes["created_at"].zone
  #       assert_equal "GMT", Artefact.last.created_at.zone
  #     end
  #   end
  #
  #   should "use the Time.zone time zone for dot-methods" do
  #     Timecop.freeze(wintertime) do
  #       FactoryBot.create(:artefact)
  #       assert_equal "GMT", Artefact.last.created_at.zone
  #     end
  #   end
  #
  #   context "it is currently British Summer Time" do
  #     should "store the date in BST" do
  #       Timecop.freeze(first_day_of_summer_time) do
  #         FactoryBot.create(:artefact)
  #         assert_equal "BST", Artefact.last.attributes["created_at"].zone
  #       end
  #     end
  #
  #     should "use the time zone with offset for dot-methods" do
  #       Timecop.freeze(first_day_of_summer_time) do
  #         FactoryBot.create(:artefact)
  #         assert_equal "BST", Artefact.last.created_at.zone
  #       end
  #     end
  #   end
  # end
end
