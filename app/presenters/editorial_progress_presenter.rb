class EditorialProgressPresenter
  include Admin::PathsHelper

  attr_accessor :scope, :column_headings

  def initialize(scope = Edition.all)
    self.scope = scope
    self.column_headings = [:title, :slug, :preview_url, :state, :format, :version_number, :assigned_to]
  end

  def build_row(item)
    column_headings.collect do |ch| 
      if ch == :preview_url
        preview_edition_path(item)
      else
        item.__send__(ch) 
      end
    end
  end

  def to_csv
    CSV.generate do |csv|
      csv << column_headings.collect { |ch| ch.to_s.humanize }
      scope.each do |item|
        csv << build_row(item)
      end
    end
  end
end