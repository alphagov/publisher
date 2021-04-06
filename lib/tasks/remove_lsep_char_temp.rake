desc "remove line seperator charactor"
task remove_lsep_character: :environment do
  editions = Edition
    .nin(state: "archived")
    .any_of(
      { body: { "$regex" => "\u2028|\u2029" } },
      { parts: { "$elemMatch" => { body: { "$regex" => "\u2028|\u2029" } } } },
    )

  editions.each(&:save!)
end
