require "test_helper"
require "licence_identifier_migrator"

class LicenceIdentifierMigratorTest < ActiveSupport::TestCase
  context "update_all" do
    setup do
      LicenceIdentifierMigrator.stubs(:mappings_as_hash).returns(
        1_083_741_393 => "123-1-1",
        1_083_741_799 => "146-7-1",
        1_084_062_157 => "898-1-1",
        1_075_329_002 => "999-4-1",
      )
      @le1 = LicenceEdition.create(licence_identifier: "1083741799", title: "Licence One", panopticon_id: FactoryBot.create(:artefact).id)
      @le2 = LicenceEdition.create(licence_identifier: "9999999999", title: "Licence Two", panopticon_id: FactoryBot.create(:artefact).id)
    end

    should "update licence editions with a matching licence identifier" do
      LicenceIdentifierMigrator.update_all
      @le1.reload
      assert_equal "146-7-1", @le1.licence_identifier
    end

    should "ignore licence editions without a matching licence identifier" do
      LicenceIdentifierMigrator.update_all
      @le2.reload
      assert_equal "9999999999", @le2.licence_identifier
    end
  end
end
