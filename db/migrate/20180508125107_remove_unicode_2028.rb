class RemoveUnicode2028 < Mongoid::Migration
  def self.up
    unicode = "\u2028"
    unicode_re = Regexp.new(unicode)
    updated = []

    Edition.where(:body => { '$regex' => unicode }, :state => { '$ne' => 'archived' }).each do |edition|
      edition.body = edition.body.gsub(unicode, '')
      updated << edition if edition.save(validate: false) # These are published editions and we don't want to go via workflow.
    end

    Edition.where(:parts => { '$elemMatch' => { :body => { '$regex' => unicode } } },
                  :state => { '$ne' => 'archived' }).each do |edition|
      edition.parts.each do |part|
        if part.body =~ unicode_re
          part.body = part.body.gsub(unicode, '')
        end
      end
      updated << edition if edition.save(validate: false)
    end

    puts "#{updated.size} editions updated."
    puts "Ids: #{updated.map(&:id).uniq.join(', ')}"
    puts "Slugs: #{updated.map(&:slug).uniq.join(', ')}"
  end

  def self.down
  end
end
