class UpdateLocalTransactionExpectations < Mongoid::Migration
  def self.up
    Expectation.find_or_create_by(text: 'Available in Wales only')

    england_only_expectation = Expectation.where(text: 'Available in England only').first
    england_and_wales_only_expectation = Expectation.where(text: 'Available in England and Wales only').first

    LocalTransactionEdition.excludes(state: 'archived')
      .any_in(expectation_ids: [england_only_expectation._id.to_s]).each do |local_transaction|
      unless local_transaction.artefact.archived?
        local_transaction.expectation_ids.delete(england_only_expectation._id.to_s)
        local_transaction.expectation_ids << england_and_wales_only_expectation._id.to_s
        puts "Updated '#{local_transaction.title}'" if local_transaction.save(validate: false)
      end
    end
  end

  def self.down
    Expectation.where(text: 'Available in Wales only').each(&:destroy)

    england_only_expectation = Expectation.where(text: 'Available in England only').first
    england_and_wales_only_expectation = Expectation.where(text: 'Available in England and Wales only').first

    LocalTransactionEdition.excludes(state: 'archived')
      .any_in(expectation_ids: [england_and_wales_only_expectation._id.to_s]).each do |local_transaction|
      unless local_transaction.artefact.archived?
        local_transaction.expectation_ids.delete(england_and_wales_only_expectation._id.to_s)
        local_transaction.expectation_ids << england_only_expectation._id.to_s
        puts "Updated '#{local_transaction.title}'" if local_transaction.save(validate: false)
      end
    end
  end
end
