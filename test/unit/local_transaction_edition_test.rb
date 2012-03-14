require 'test_helper'
require_relative 'helpers/local_services_helper'

class LocalTransactionEditionTest < ActiveSupport::TestCase
  include LocalServicesHelper

  context "a local transaction for the 'bins' service" do
    setup do
      @lgsl_code = 'bins'
      @bins_transaction = LocalTransactionEdition.new(lgsl_code: @lgsl_code, name: "Transaction", slug: "slug", panopticon_id: 1, title: "Transaction")
    end

    context "an authority exists providing the 'housing-benefit' service" do
      setup { @county_council = make_authority_providing('housing-benefit') }

      should "report that that authority does not provide the bins service" do
        assert ! @bins_transaction.service_provided_by?(@county_council.snac)
      end
    end

    context "an authority exists providing 'bins' service" do
      setup { @county_council = make_authority_providing('bins') }

      should "report that that authority provides the bins service" do
        assert @bins_transaction.service_provided_by?(@county_council.snac)
      end

      should "report that some other authority does not provide the bins service" do
        assert ! @bins_transaction.service_provided_by?('some_other_snac')
      end
    end

    should "report the search_format to be 'transaction'" do
      assert_equal "transaction", @bins_transaction.search_format
    end
  end

  context "when saving" do
    should "validate that a LocalService exists for that lgsl_code" do
      s = LocalService.create!(lgsl_code: 'bins', providing_tier: %w{county unitary})

      lt = LocalTransactionEdition.new(lgsl_code: 'nonexistent', name: "Foo", slug: "foo", panopticon_id: 1, title: "Foo")
      lt.save
      assert !lt.valid?

      lt = LocalTransactionEdition.new(lgsl_code: s.lgsl_code, name: "Bar", slug: "bar", panopticon_id: 1, title: "Foo")
      lt.save
      assert lt.valid?
      assert lt.persisted?
    end
  end

  context "when publishing a new version" do
    setup do
      make_service(149, %w{county unitary})
      @edition_one = LocalTransactionEdition.new(:name => "Transaction", :slug => "transaction", :lgsl_code => "149", :panopticon_id => 1, :title => "Transaction")
      @user = User.create :name => 'Thomas'
    end

    should "create a diff between the versions" do
      @edition_one.introduction = 'Test'
      @edition_one.state = :ready
      @edition_one.save!

      @user.publish @edition_one, comment: "First edition"

      edition_two = @edition_one.build_clone
      edition_two.introduction = "Testing"
      edition_two.state = :ready
      edition_two.save!

      @user.publish edition_two, comment: "Second edition"

      publish_action = edition_two.actions.where(request_type: "publish").last

      assert_equal "{\"Test\" >> \"Testing\"}", publish_action.diff

    end
  end

end
