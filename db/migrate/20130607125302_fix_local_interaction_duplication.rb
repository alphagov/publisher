class FixLocalInteractionDuplication < Mongoid::Migration
  def self.up
    LocalAuthority.all.each do |la|
      interactions = la.local_interactions.group_by {|i| [i.lgsl_code, i.lgil_code] }
      interactions.each do |key, values|
        next if values.size <= 1

        puts "Found #{values.size} entries for lgsl:#{key[0]} lgil:#{key[1]} for #{la.name}(#{la.snac})"
        first = values.shift
        values.each do |i|
          if i.url == first.url
            i.destroy
          else
            puts "  Non-matching URL, won't destroy"
          end
        end
      end
    end
  end

  def self.down
  end
end
