namespace :tmp_zendesk_5819067 do
  desc "Fix a couple of artefacts which have the wrong 'kind'"
  task fix_artefact_kinds: :environment do
    eco = Artefact.find_by(slug: "energy-company-obligation")
    if eco.latest_edition.instance_of?(AnswerEdition) && eco.kind != "answer"
      eco.kind = "answer"
      eco.save!
    else
      puts "Skipping energy-company-obligation - had kind #{eco.kind} and latest edition class #{eco.latest_edition.class}"
    end

    mytc = Artefact.find_by(slug: "manage-your-tax-credits")
    if mytc.latest_edition.instance_of?(TransactionEdition) && mytc.kind != "transaction"
      mytc.kind = "transaction"
      mytc.save!
    else
      puts "Skipping manage-your-tax-credits - had kind #{mytc.kind} and latest edition class #{mytc.latest_edition.class}"
    end
  end
end
