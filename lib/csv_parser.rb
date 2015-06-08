require 'csv'

class CSVParser
  def initialize(file)
    @file = file
  end

  def parse
    contents = @file.read

    if contents.empty?
      raise RuntimeError.new("can't parse an empty file")
    end

    CSV.new(contents, headers: true).to_a.map do |row|
      row.to_hash.symbolize_keys
    end
  end
end
