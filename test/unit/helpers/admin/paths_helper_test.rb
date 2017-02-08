require 'test_helper'

class PathsHelperTest < ActionView::TestCase
  context "#preview_edition_path" do
    context "for migrated formats" do
      should "return path for draft stack" do
        edition = stub(version_number: 1, migrated?: true, id: 999, slug: "for-funzies")

        expected_base_path = Plek.current.find("draft-frontend")
        expected_path = "#{expected_base_path}/for-funzies?cache=1234"

        assert_equal expected_path, preview_edition_path(edition, 1234)
      end
    end

    context "for non-migrated formats" do
      should "return path for private frontend" do
        edition = stub(version_number: 1, migrated?: false, id: 999, slug: "for-funzies")

        expected_base_path = Plek.current.find("private-frontend")
        expected_path = "#{expected_base_path}/for-funzies?edition=1&cache=9876"

        assert_equal expected_path, preview_edition_path(edition, 9876)
      end
    end
  end
end
