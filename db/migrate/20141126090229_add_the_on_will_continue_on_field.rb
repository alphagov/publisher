class AddTheOnWillContinueOnField < Mongoid::Migration
  def self.up
    puts "Adding 'the' to the beginning of `will_continue_on` text on business support editions"
    # BS editions which do not begin with 'The' or 'the'
    BusinessSupportEdition.where(will_continue_on: /\A(?!the\s).*/i).each do |bs_edition|
      bs_edition.set(:will_continue_on, "the #{bs_edition.will_continue_on}") if bs_edition.will_continue_on.strip.present?
    end
    puts "Done."
  end

  def self.down
  end
end
