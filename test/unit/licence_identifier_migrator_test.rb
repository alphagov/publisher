require 'test_helper'
require 'licence_identifier_migrator'

class LicenceIdentifierMigratorTest < ActiveSupport::TestCase
  context "update_all" do
    setup do
      LicenceIdentifierMigrator.stubs(:mappings_as_hash).returns({
        "1083741393" => "1040001",
        "1083741799" => "1620001",
        "1084062157" => "1580003",
        "1075329002" => "1610001"
      })
      @le1 = LicenceEdition.create(licence_identifier: "1083741799", title: "Licence One", panopticon_id: 123)
      @le2 = LicenceEdition.create(licence_identifier: "9999999999", title: "Licence Two", panopticon_id: 321)
    end
    
    should "update licence editions with a matching licence identifier" do
      LicenceIdentifierMigrator.update_all
      @le1.reload
      assert_equal "1620001", @le1.licence_identifier
    end
    
    should "ignore licence editions without a matching licence identifier" do
      LicenceIdentifierMigrator.update_all
      @le2.reload
      assert_equal "9999999999", @le2.licence_identifier
    end
  end
end
