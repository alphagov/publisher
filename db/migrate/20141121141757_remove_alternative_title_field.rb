class RemoveAlternativeTitleField < Mongoid::Migration
  def self.up
    Edition.all.each { |edition| edition.unset(:alternative_title) }
  end

  def self.down
    # No down as this is a destructive action.
  end
end
