# Eventually my data will live somewhere else and I'll not be just a thin wrapper around Publications
class RelatedItem
  attr_accessor :item
  private :item=, :item
  def initialize item
    self.item = item
  end

  def format
    item.class.name.tableize.singularize
  end

  def path
    '/' + id
  end

  def name
    item.name
  end

  def id
    item.slug
  end

  def to_s
    item.name
  end

  def published?
    item.has_published
  end

  include Comparable
  def <=> other
    sort_key <=> other.sort_key
  end

  def sort_key
    item.name
  end

  def self.all
    Publication.all.map { |p| RelatedItem.new p }.sort
  end

  def self.find slug
    publication = Publication.where slug: slug
    return unless publication.any?
    RelatedItem.new publication.first
  end
end
