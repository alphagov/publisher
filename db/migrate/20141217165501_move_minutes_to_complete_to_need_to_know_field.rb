class MoveMinutesToCompleteToNeedToKnowField < Mongoid::Migration
  def self.up
    Edition.where(:minutes_to_complete.ne => "", :minutes_to_complete.exists => true).each do |edition|
      edition.set(:need_to_know, "- Takes around #{edition.minutes_to_complete} minutes\r\n#{edition.need_to_know}")
    end

    Edition.all.each { |edition| edition.unset(:minutes_to_complete) }
  end

  def self.down
    # No down as this can't reliably be extracted from the need_to_know field
  end
end
