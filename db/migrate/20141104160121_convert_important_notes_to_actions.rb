class ConvertImportantNotesToActions < Mongoid::Migration
  def self.up
    Edition.where(:important_note.nin => ['', nil]).each do |e|
      e.actions.create!(request_type: 'important_note',
                        comment: e['important_note'],
                        created_at: e.updated_at)
    end
  end

  def self.down
  end
end
