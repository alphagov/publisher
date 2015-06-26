require 'csv'

class CSVPresenter
  def initialize(scope)
    self.scope = scope
    self.column_headings ||= []
  end

  def to_csv
    CSV.generate do |csv|
      build_csv(csv)
    end
  end

  def write_csv(path)
    CSV.open(File.join(path, "#{report_name}.csv"), "wb") do |csv|
      build_csv(csv)
    end
  end

  def filename
    "#{report_name}-#{Date.today.strftime("%F")}"
  end

  def report_name
    self.class.name.gsub(/Presenter/, '').underscore
  end

protected

  attr_accessor :scope, :column_headings

private

  def build_row(item)
    column_headings.collect do |ch|
      get_value(ch, item)
    end
  end

  def get_value(heading, item)
    item.__send__(heading) if item.respond_to?(heading)
  end

  def build_csv(csv)
    csv << column_headings.collect { |ch| ch.to_s.humanize }
    scope.each do |item|
      csv << build_row(item)
    end
  end
end
