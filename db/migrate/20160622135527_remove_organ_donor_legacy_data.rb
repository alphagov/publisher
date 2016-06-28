class RemoveOrganDonorLegacyData < Mongoid::Migration
  def self.up
    # "Editing of an edition with an Archived artefact is not allowed".
    CompletedTransactionEdition.skip_callback(:save, :before, :check_for_archived_artefact)

    CompletedTransactionEdition.each do |edition|
      puts "Migrating promotion choice data for #{edition.slug} (#{edition.state})"

      # Moving organ_donor_registration into promotion_choice
      if edition.presentation_toggles.fetch("organ_donor_registration", {})["promote_organ_donor_registration"]
        edition.promotion_choice = "organ_donor"
        edition.promotion_choice_url = edition.presentation_toggles["organ_donor_registration"]["organ_donor_registration_url"]
      end

      # Removing all organ_donor_registration data
      edition.presentation_toggles.delete("organ_donor_registration")

      if edition.presentation_toggles.empty?
        edition.presentation_toggles = edition.class.default_presentation_toggles
      end

      edition.save!(validate: false)
    end
  end

  def self.down
    # "Editing of an edition with an Archived artefact is not allowed".
    CompletedTransactionEdition.skip_callback(:save, :before, :check_for_archived_artefact)

    CompletedTransactionEdition.each do |edition|
      puts "Migrating organ donor registration choice data for #{edition.slug} (#{edition.state})"

      edition.presentation_toggles["organ_donor_registration"] =
        if edition.promotion_choice == 'organ_donor'
          {
            "promote_organ_donor_registration" => true,
            "organ_donor_registration_url" => edition.promotion_choice_url
          }
        else
          {
            "promote_organ_donor_registration" => false,
            "organ_donor_registration_url" => ''
          }
        end

      edition.save!(validate: false)
    end
  end
end
