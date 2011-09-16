class RelatedItem
  attr_accessor :item
  private :item=, :item
  def initialize item
    self.item = item
  end

  def id
    item.slug
  end

  def to_s
    item.name
  end

  include Comparable
  def <=> other
    sort_key <=> other.sort_key
  end

  def sort_key
    item.name
  end

  # Eventually I will live somewhere else and not be a thin wrapper around Publications
  def self.all
    Publication.all.map { |p| RelatedItem.new p }.sort
  end
end
