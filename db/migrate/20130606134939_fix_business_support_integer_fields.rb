# encoding: utf-8
class FixBusinessSupportIntegerFields < Mongoid::Migration
  FIELDS = [ :min_value, :max_value, :max_employees ]
  def self.up
    BusinessSupportEdition.all.each do |ed|
      FIELDS.each do |field|
        if (value = ed.send(field)).is_a?(String)
          puts "Fixing string in #{field} field for #{ed.slug} version:#{ed.version_number}"

          new_value = value.gsub(/[£,]/, '')
          if new_value =~ /\A\d+\z/
            ed.send("#{field}=", new_value.to_i)
          else
            puts "  Couldn't convert value #{value} to an integer"
          end
        end
      end
      if ed.changed?
        ed.save! :validate => false # validate => false so we can save published/archived editions
      end
    end
  end

  def self.down
  end
end
