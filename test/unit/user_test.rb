require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "creating a transaction with the initial details creates a valid transaction" do
    user = User.create(:name => "bob")
    without_panopticon_validation do
      trans = user.create_publication(:transaction, :name => "test", :slug => "test")
      assert trans.valid?
    end
  end
end
