class LocalAuthorityInteractionGhostDetector

  attr_reader :input_data

  def initialize(input_data)
    @input_data = input_data
  end

  def detect_ghosts
    local_authorities.each do |la|
      la.local_interactions.to_a.each do |lai|
        yield la, lai, ghost_status(la, lai)
      end
    end
  end

private
  def ghost_status(authority, interaction)
    if directgov_interactions.key? authority.snac.to_s
      interactions = directgov_interactions[authority.snac.to_s]
      interaction_key = [interaction.lgsl_code.to_s, interaction.lgil_code.to_s]
      if interactions.key? interaction_key
        if interactions[interaction_key].upcase == 'X'
          :interaction_in_input_to_be_deleted
        else
          :interaction_in_input
        end
      else
        :interaction_not_in_input
      end
    else
      :authority_not_in_input
    end
  end

  def local_authorities
    @_local_authorities ||= LocalAuthority.all.to_a
  end

  def directgov_interactions
    @_directgov_interactions ||= prepare_directgov_interactions
  end

  def prepare_directgov_interactions
    # CSV Headers: "Authority Name,SNAC,LAid,Service Name,LGSL,LGIL,Service URL,Last Updated"
    CSV.new(input_data, headers: true).
      reject { |row| row['SNAC'].nil? || row['SNAC'].strip.blank? }.
      each.
      with_object({}) do |row, result|
        snac = row['SNAC'].to_s
        result[snac] ||= {}
        interaction_key = [row['LGSL'].to_s, row['LGIL'].to_s]
        result[snac][interaction_key] = row['Service URL'].to_s.strip
      end
  end
end
