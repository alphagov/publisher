desc "Add bank holidays to the Bank Holidays page"
task add_bank_holidays: [:environment] do
  content_id = "58f79dbd-e57f-4ab2-ae96-96df5767d1b2".freeze
  bank_holidays = BankHolidaysEdition.new(title: "Bank Holidays",
                                          year: [{ title: "Christmas Day", date: "25 December"},
                                                       { title: "Boxing Day", date: "26 December" },
                                                  ])

    # bank_holidays.save!
  
rescue StandardError => e
  puts "Encountered error #{e.message}"
end