require 'set'

class LocalServiceCleaner
  def initialize(input_data = LocalServiceImporter.fetch_data)
    @input_data = input_data
  end

  def run
    LocalService.all.each do |local_service|
      print "Looking at #{local_service.lgsl_code} -"
      if in_csv? local_service
        puts " in csv"
      elsif in_local_transaction? local_service
        puts " in local transaction"
      else
        puts " removed"
        local_service.destroy!
      end
    end
  end

  def lgsls_from_csv
    @_lgsls_from_csv ||= fetch_lgsls_from_csv
  end

private

  def in_csv?(local_service)
    lgsls_from_csv.include? local_service.lgsl_code
  end

  def in_local_transaction?(local_service)
    LocalTransactionEdition.where(lgsl_code: local_service.lgsl_code).any?
  end

  def fetch_lgsls_from_csv
    output = Set.new
    CSV.new(@input_data, headers: true).
      each.with_object(output) do |row, lgsls|
        lgsls.add row['LGSL'].to_i
      end
    output
  ensure
    @input_data.close unless @input_data.nil? || @input_data.closed?
  end
end
