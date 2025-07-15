require "test_helper"
require "rake"

class ImportJsonTaskTest < ActiveSupport::TestCase
  setup do
    @import_json_task = Rake::Task["import:json"]
    @import_json_task.reenable
    TOTAL_USER_COUNT = 791
    seed_user_data unless User.count == TOTAL_USER_COUNT
  end

  def seed_user_data
    file_with_user_data = "test/fixtures/migration/mongo_user_data.json"
    @import_json_task.invoke("User", file_with_user_data)
    @import_json_task.reenable
  end

  should "insert Edition correctly from json file record" do
    file_with_guide_edition_artefact_data = "test/fixtures/migration/mongo_guide_edition_artefact_data.json"
    @import_json_task.invoke("Artefact", file_with_guide_edition_artefact_data)
    @import_json_task.reenable

    file_with_guide_edition_data = "test/fixtures/migration/mongo_guide_edition_data.json"
    @import_json_task.invoke("Edition", file_with_guide_edition_data)

    assert_equal 1, Edition.count
  end

  should "insert Editionable correctly from the json file record" do
    file_with_guide_edition_artefact_data = "test/fixtures/migration/mongo_guide_edition_artefact_data.json"
    @import_json_task.invoke("Artefact", file_with_guide_edition_artefact_data)
    @import_json_task.reenable

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
      file_with_simple_smart_answer_artefact_data = "test/fixtures/migration/mongo_simple_smart_answer_edition_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_simple_smart_answer_artefact_data)
      @import_json_task.reenable
      file_with_simple_smart_answer_edition_data = "test/fixtures/migration/mongo_simple_smart_answer_edition_data.json"
      @import_json_task.invoke("Edition", file_with_simple_smart_answer_edition_data)

      assert_equal 1, Edition.count, "No edition added"
      assert_equal 1, SimpleSmartAnswerEdition.count, "No node added"
    end

    should "insert SimpleSmartAnswerEdition::Nodes correctly from json file record" do
      file_with_simple_smart_answer_artefact_data = "test/fixtures/migration/mongo_simple_smart_answer_edition_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_simple_smart_answer_artefact_data)
      @import_json_task.reenable
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
      file_with_place_edition_artefact_data = "test/fixtures/migration/mongo_place_edition_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_place_edition_artefact_data)
      @import_json_task.reenable

      file_with_place_edition_artefact_data = "test/fixtures/migration/mongo_place_edition_data.json"
      @import_json_task.invoke("Edition", file_with_place_edition_artefact_data)

      assert_equal 1, Edition.count
      assert_equal 1, PlaceEdition.count
    end
  end

  context "AnswerEdition" do
    should "insert AnswerEdition correctly from json file record" do
      file_with_answer_edition_artefact_data = "test/fixtures/migration/mongo_answer_edition_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_answer_edition_artefact_data)
      @import_json_task.reenable

      file_with_answer_edition_data = "test/fixtures/migration/mongo_answer_edition_data.json"
      @import_json_task.invoke("Edition", file_with_answer_edition_data)

      assert_equal 1, Edition.count
      assert_equal 1, AnswerEdition.count
    end
  end

  context "TransactionEdition" do
    should "insert TransactionEdition correctly from json file record" do
      file_with_transaction_edition_artefact_data = "test/fixtures/migration/mongo_transaction_edition_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_transaction_edition_artefact_data)
      @import_json_task.reenable
      file_with_transaction_edition_data = "test/fixtures/migration/mongo_transaction_edition_data.json"
      @import_json_task.invoke("Edition", file_with_transaction_edition_data)

      assert_equal 1, Edition.count
      assert_equal 1, TransactionEdition.count
    end

    should "insert TransactionEdition and variant correctly from json file record" do
      file_with_transaction_edition_with_variant_artefact_data = "test/fixtures/migration/mongo_transaction_edition_with_variant_data_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_transaction_edition_with_variant_artefact_data)
      @import_json_task.reenable
      file_with_transaction_edition_with_variant_data = "test/fixtures/migration/mongo_transaction_edition_with_variant_data.json"
      @import_json_task.invoke("Edition", file_with_transaction_edition_with_variant_data)
      transaction_variant = Variant.where(mongo_id: "5c18df2eed915d22e59f6a30").last

      assert_equal 1, Edition.count
      assert_equal 1, TransactionEdition.count
      assert_equal "https://www.tax.service.gov.uk/check-your-state-pension/signin/verify", transaction_variant.link
    end
  end

  context "HelpPageEdition" do
    should "insert HelpPageEdition correctly from json file record" do
      file_with_help_page_artefact_data = "test/fixtures/migration/mongo_help_page_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_help_page_artefact_data)
      @import_json_task.reenable
      file_with_help_page_edition_data = "test/fixtures/migration/mongo_help_page_edition_data.json"
      @import_json_task.invoke("Edition", file_with_help_page_edition_data)

      assert_equal 1, Edition.count
      assert_equal 1, HelpPageEdition.count
    end
  end

  context "CompletedTransactionEdition" do
    should "insert TransactionEdition correctly from json file record" do
      file_with_completed_transaction_artefact_data = "test/fixtures/migration/mongo_completed_transaction_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_completed_transaction_artefact_data)
      @import_json_task.reenable
      file_with_completed_transaction_edition_data = "test/fixtures/migration/mongo_completed_transaction_edition_data.json"
      @import_json_task.invoke("Edition", file_with_completed_transaction_edition_data)

      assert_equal 1, Edition.count
      assert_equal 1, CompletedTransactionEdition.count
    end
  end

  context "Users" do
    should "insert User correctly from json file record" do
      assert_equal 791, User.count
      assert_equal "633ea4aa8fa8f54662895951", User.last.mongo_id
      assert_equal ["signin", "welsh_editor"], User.last.permissions
      assert_equal "329428f0-0070-013b-4e5d-02ede1ddf010", User.last.uid
      assert_equal "maria.morris@justice.gov.uk", User.last.email
      assert_equal "Maria Morris", User.last.name
      assert_equal "hm-courts-and-tribunals-service", User.last.organisation_slug
      assert_equal "6f757605-ab8f-4b62-84e4-99f79cf085c2", User.last.organisation_content_id
    end

    should "update the edition assigned_to_id to new postgres ID using old mongo ID to match user" do
      file_with_guide_edition_artefact_data = "test/fixtures/migration/mongo_guide_edition_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_guide_edition_artefact_data)
      @import_json_task.reenable
      file_with_guide_edition_data = "test/fixtures/migration/mongo_guide_edition_data.json"
      @import_json_task.invoke("Edition", file_with_guide_edition_data)

      assigned_to_id = Edition.where("editionable_type": "GuideEdition").last.assigned_to_id
      assigned_to_user = User.find(assigned_to_id)

      assert_equal "623078cbd3bf7f203b47947a", assigned_to_user.mongo_id
    end

    should "log an error and not save Edition if old mongo id does not match any user" do
      nonexistent_assigned_to_id = "test/fixtures/migration/mongo_edition_with_nonexistent_assigned_to_id_data.json"

      assert_output(/Error: assigned to user with mongo_id 4f7974a0a4254a2c9f00011c does not exist/) do
        @import_json_task.invoke("Edition", nonexistent_assigned_to_id)
      end
      assert_equal 0, Edition.count
    end
  end

  context "Actions" do
    should "add all the actions for the edition" do
      file_with_guide_edition_artefact_data = "test/fixtures/migration/mongo_guide_edition_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_guide_edition_artefact_data)
      @import_json_task.reenable

      file_with_guide_edition_data = "test/fixtures/migration/mongo_guide_edition_data.json"
      @import_json_task.invoke("Edition", file_with_guide_edition_data)

      assert_equal 5, Action.count

      assert_equal Edition.where(editionable_type: "GuideEdition").first.actions[1].requester_id, User.where(mongo_id: "623078cbd3bf7f203b47947a").first.id
      assert_equal Edition.where(editionable_type: "GuideEdition").first.actions[1].recipient_id, User.where(mongo_id: "623078cbd3bf7f203b47947a").first.id
      assert_equal Edition.where(editionable_type: "GuideEdition").first.actions[4].requester_id, User.where(mongo_id: "60a26d41d3bf7f719f9533dd").first.id
    end

    should "log an error if old mongo id does not match any requester for the action" do
      file_with_guide_no_requester_artefact_data = "test/fixtures/migration/mongo_guide_edition_no_requester_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_guide_no_requester_artefact_data)
      @import_json_task.reenable

      nonexistent_requester_to_id = "test/fixtures/migration/mongo_guide_edition_with_nonexistant_requester_id_for_first_action_data.json"

      assert_output(/Error: requester user with mongo_id 623078cbd3bf7f203b47947b does not exist/) do
        @import_json_task.invoke("Edition", nonexistent_requester_to_id)
      end
    end

    should "log an error Edition if old mongo id does not match any recipient for the action" do
      file_with_guide_no_recipient_artefact_data = "test/fixtures/migration/mongo_guide_edition_no_recipient_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_guide_no_recipient_artefact_data)
      @import_json_task.reenable
      nonexistent_recipient_to_id = "test/fixtures/migration/mongo_guide_edition_with_nonexistant_recipient_id_for_first_action_data.json"

      assert_output(/Error: recipient user with mongo_id 623078cbd3bf7f203b47947b does not exist/) do
        @import_json_task.invoke("Edition", nonexistent_recipient_to_id)
      end
    end
  end

  context 'Artefact' do
    should 'insert Artefact correctly from json file record' do
      file_with_artefact_data = "test/fixtures/migration/mongo_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_artefact_data)
      created_artefact = Artefact.last

      assert_equal 1, Artefact.count
      assert_equal "4fa11ce19d5eb5495b000049", created_artefact.mongo_id
      assert_equal "bereavement-allowance", created_artefact.slug
      assert_equal ["/bereavement-allowance.json"], created_artefact.paths
      assert_equal ["/bereavement-allowance"], created_artefact.prefixes
      assert_equal "1e9de9b2-76d1-403c-ba80-81f115e158f0", created_artefact.content_id
    end

    should "add all the actions for the artefact" do
      file_with_artefact_data = "test/fixtures/migration/mongo_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_artefact_data)

      assert_equal 36, ArtefactAction.count
      assert_equal 36, Artefact.last.artefact_actions.count
      assert_equal User.where(mongo_id: "4f7974a0a4254a2c9f00001b").last.id, Artefact.last.artefact_actions[10].user_id
      assert_equal "51387db9ed915d586f00000e", Artefact.last.artefact_actions[10].mongo_id
      assert_equal "update", Artefact.last.artefact_actions[10].action_type
    end

    should 'add all external_links for an Artefact' do
      file_with_artefact_and_link_data = "test/fixtures/migration/mongo_artefact_with_external_links_data.json"
      @import_json_task.invoke("Artefact", file_with_artefact_and_link_data)
      external_link = ArtefactExternalLink.where(mongo_id: "6760222e1cfe840014d535e5").last

      assert_equal 5, ArtefactExternalLink.count
      assert_equal 5, Artefact.last.external_links.count
      assert_equal " A child's legal rights (NSPCC)", external_link.title
      assert_equal "https://www.nspcc.org.uk/preventing-abuse/child-protection-system/legal-defin", external_link.url
    end
  end

  context 'LocalService' do
    should "insert LocalService correctly from json file record" do
      file_with_local_services_data = "test/fixtures/migration/mongo_local_service_data.json"
      @import_json_task.invoke("LocalService", file_with_local_services_data)

      assert_equal 135, LocalService.count

      assert_equal "Find out abut school transport for a child with special educational needs", LocalService.where(mongo_id: "4f340dce1d41c87e59000009").first.description
      assert_equal ["county", "unitary"], LocalService.where(mongo_id: "4f340dce1d41c87e59000009").first.providing_tier
      assert_equal 40, LocalService.where(mongo_id: "4f340dce1d41c87e59000009").first.lgsl_code
    end
  end

  context 'OverviewDashboard' do
    should "insert OverviewDashboard correctly from json file record" do
      file_with_overview_dashboard_data = "test/fixtures/migration/mongo_overview_dashboard_data.json"
      @import_json_task.invoke("OverviewDashboard", file_with_overview_dashboard_data)
      overview_dashboard = OverviewDashboard.where(mongo_id: "504472529d5eb535de000066").last

      assert_equal 118, OverviewDashboard.count
      assert_equal 'Section', overview_dashboard.dashboard_type
      assert_equal 'Driving:MOT', overview_dashboard.result_group
      assert_equal 5, overview_dashboard.count
    end
  end

  context 'LinkCheckReports' do
    should "insert LinkCheckReport and child Links correctly from json record" do
      file_with_link_check_report_artefact_data = "test/fixtures/migration/mongo_link_check_reports_artefact_data.json"
      @import_json_task.invoke("Artefact", file_with_link_check_report_artefact_data)
      @import_json_task.reenable
      file_with_link_check_report_data = "test/fixtures/migration/mongo_edition_with_link_checker_reports_data.json"
      @import_json_task.invoke("Edition", file_with_link_check_report_data)
      link_check_report = LinkCheckReport.where(mongo_id: "67af61a20ce2cb0014028ddf").last
      link = Link.where(mongo_id: "67af61a20ce2cb0014028dc4").last

      assert_equal 1, LinkCheckReport.count
      assert_equal 51, link_check_report.links.count
      assert_equal 24084930, link_check_report.batch_id
      assert_equal "https://www.eoni.org.uk/Vote/Voting-by-post-or-proxy", link.uri
    end
  end

  context 'Homepage PopularLinks' do
    should "insert PopularLinksEdition and child LinkItems correctly from json record" do
      file_with_popular_links_data = "test/fixtures/migration/mongo_popular_links_edition_data.json"
      @import_json_task.invoke("Edition", file_with_popular_links_data)
      assert_equal 1, PopularLinksEdition.count
    end
  end
end