require 'test_helper'
require 'local_transactions_importer'

class LocalTransactionsImporterTest < ActiveSupport::TestCase
  def sample_csv
    StringIO.new <<-eos
Authority Name,SNAC,LAid,Service Name,LGSL,LGIL,Service URL
Adur District Council,45UB,1,Find out about school holiday schemes,18,8,http://www.adur.gov.uk/education/index.htm
Adur District Council,45UB,1,Find out about after/before school childcare,19,8,http://www.adur.gov.uk/education/index.htm
Adur District Council,45UB,1,Find out about local organisations for students,47,8,http://www.adur.gov.uk/education/index.htm
Adur District Council,45UB,1,Pay your council tax,57,2,http://www.adur.gov.uk/council-tax/index.htm
eos
  end

  setup do
    @importer = LocalTransactionsImporter.new(sample_csv)
  end

  test "it creates an authority with correct details" do
    @importer.run
    new_authority = Authority.where(snac: '45UB').first
    assert new_authority
    assert_equal 'Adur District Council', new_authority.name
  end

  test "it doesn't recreate an existing authority" do
    @importer.expects(:ensure_authority).once
    @importer.run
  end

  test "it creates an LGSL record" do
    @importer.run
    lts = LocalTransactionsSource.find_current_lgsl(18)
    assert lts
  end
end