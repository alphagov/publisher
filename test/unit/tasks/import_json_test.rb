require "test_helper"
require "rake"

class ImportJsonTaskTest < ActiveSupport::TestCase
  setup do
    @import_json_task = Rake::Task["import:json"]
    @import_json_task.reenable
  end

  should "insert Edition correctly from json file record" do
    file_with_guide_edition_data = "test/fixtures/migration/mongo_guide_edition_data.json"
    @import_json_task.invoke("Edition", file_with_guide_edition_data)

    assert_equal 1, Edition.count
  end

  should "insert Editionable correctly from the json file record" do
    file_with_guide_edition_data = "test/fixtures/migration/mongo_guide_edition_data.json"
    @import_json_task.invoke("Edition", file_with_guide_edition_data)

    assert_equal 1, GuideEdition.count
    assert_equal 3, GuideEdition.last.parts.count
  end

  context "when record does not have DevolvedAdministrationAvailability" do
    should "insert LocalTransactionEdition with no DevolvedAdministrationAvailability data in the json" do
      file_with_local_transaction_edition_data = "test/fixtures/migration/mongo_local_transaction_edition_data.json"
      @import_json_task.invoke("Edition", file_with_local_transaction_edition_data)

      assert_equal 1, LocalTransactionEdition.count
      assert_equal 3, DevolvedAdministrationAvailability.count
    end
  end

  context "when record has DevolvedAdministrationAvailability" do
    should "insert LocalTransactionEdition and copy DevolvedAdministrationAvailability data from the json" do
      file_with_local_transaction_edition_data = "test/fixtures/migration/mongo_local_transaction_edition_data_devolved_admin.json"
      @import_json_task.invoke("Edition", file_with_local_transaction_edition_data)

      assert_equal 1, LocalTransactionEdition.count
      assert_equal 3, DevolvedAdministrationAvailability.count

      dev_admin_recs = DevolvedAdministrationAvailability.last(3)

      assert_equal "ScotlandAvailability", dev_admin_recs[0].type
      assert_equal "https://www.mygov.scot/self-isolation-grant",
                   dev_admin_recs[0].alternative_url
      assert_equal "WalesAvailability", dev_admin_recs[1].type
      assert_equal "https://gov.wales/self-isolation-support-scheme",
                   dev_admin_recs[1].alternative_url
      assert_equal "NorthernIrelandAvailability", dev_admin_recs[2].type
      assert_equal "https://www.nidirect.gov.uk/information-and-services/coronavirus-covid-19/financial-help-and-practical-support",
                   dev_admin_recs[2].alternative_url
    end
  end

  context "SimpleSmartAnswerEdition" do
    should "insert SimpleSmartAnswerEdition correctly from json file record" do
      file_with_simple_smart_answer_edition_data = "test/fixtures/migration/mongo_simple_smart_answer_edition_data.json"
      @import_json_task.invoke("Edition", file_with_simple_smart_answer_edition_data)

      assert_equal 1, Edition.count
      assert_equal 1, SimpleSmartAnswerEdition.count
    end

    should "insert SimpleSmartAnswerEdition::Nodes correctly from json file record" do
      file_with_simple_smart_answer_edition_data = "test/fixtures/migration/mongo_simple_smart_answer_edition_data.json"
      @import_json_task.invoke("Edition", file_with_simple_smart_answer_edition_data)

      assert_equal 1, Edition.count
      assert_equal 1, SimpleSmartAnswerEdition.count
      assert_equal 17, SimpleSmartAnswerEdition::Node.count
      assert_equal 17, SimpleSmartAnswerEdition::Node::Option.count
    end
  end

  context "PlaceEdition" do
    should "insert PlaceEdition correctly from json file record" do
      file_with_place_edition_data = "test/fixtures/migration/mongo_place_edition_data.json"
      @import_json_task.invoke("Edition", file_with_place_edition_data)

      assert_equal 1, Edition.count
      assert_equal 1, PlaceEdition.count
    end
  end

  context "AnswerEdition" do
    should "insert AnswerEdition correctly from json file record" do
      file_with_answer_edition_data = "test/fixtures/migration/mongo_answer_edition_data.json"
      @import_json_task.invoke("Edition", file_with_answer_edition_data)

      assert_equal 1, Edition.count
      assert_equal 1, AnswerEdition.count
    end
  end

  context "TransactionEdition" do
    should "insert TransactionEdition correctly from json file record" do
      file_with_transaction_edition_data = "test/fixtures/migration/mongo_transaction_edition_data.json"
      @import_json_task.invoke("Edition", file_with_transaction_edition_data)

      assert_equal 1, Edition.count
      assert_equal 1, TransactionEdition.count
    end
  end

  context "HelpPageEdition" do
    should "insert TransactionEdition correctly from json file record" do
      file_with_help_page_edition_data = "test/fixtures/migration/mongo_help_page_edition_data.json"
      @import_json_task.invoke("Edition", file_with_help_page_edition_data)

      assert_equal 1, Edition.count
      assert_equal 1, HelpPageEdition.count
    end
  end

  context "Users" do
    should "insert User correctly from json file record" do
      file_with_user_data = "test/fixtures/migration/mongo_user_data.json"
      @import_json_task.invoke("User", file_with_user_data)

      assert_equal 1, User.count
      assert_equal "670cea84a90e05001d898d1e", User.last.mongo_id
      assert_equal ["signin"], User.last.permissions
      assert_equal "f65d93a0-d55c-013b-1567-3e3f44448a15", User.last.uid
      assert_equal "syed.ali1@digital.cabinet-office.gov.uk", User.last.email
      assert_equal "Syed Ali", User.last.name
      assert_equal "government-digital-service", User.last.organisation_slug
      assert_equal "af07d5a5-df63-4ddc-9383-6a666845ebe9", User.last.organisation_content_id
    end
  end
end