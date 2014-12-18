class MoveMinutesToCompleteToNeedToKnowField < Mongoid::Migration
  def self.up
    Edition.where(:minutes_to_complete.nin => ["", nil]).each do |edition|
      language = edition.artefact.language

      if language == 'cy'
        edition.set(:need_to_know, "- Mae'n cymryd tua #{edition.minutes_to_complete} munud\r\n#{edition.need_to_know}")
      else
        edition.set(:need_to_know, "- Takes around #{edition.minutes_to_complete} minutes\r\n#{edition.need_to_know}")
      end
    end

    Edition.all.each { |edition| edition.unset(:minutes_to_complete) }
  end

  def self.down
    # No down as this can't reliably be extracted from the need_to_know field
  end
end
