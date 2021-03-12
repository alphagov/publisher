require "test_helper"

class LocalServiceTaskTest < ActiveSupport::TestCase
  test "running the local_service:change_lgsl_code_10001 rake task changes the LGSL code" do
    service = FactoryBot.create(:local_service, lgsl_code: 100_001)
    edition = FactoryBot.create(:local_transaction_edition, lgsl_code: 100_001, lgil_code: 1)

    Rake::Task["local_service:change_lgsl_code_100001"].execute
    assert_equal 1827, service.reload.lgsl_code
    assert_equal 1827, edition.reload.lgsl_code
  end
end
