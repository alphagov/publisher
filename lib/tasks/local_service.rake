namespace :local_service do
  desc "Update the temporary LGSL code of 100001"
  task change_lgsl_code_100001: :environment do
    draft = LocalTransactionEdition.find_by!(lgsl_code: 100_001, state: :draft)
    LocalService.find_by!(lgsl_code: 100_001).update!(lgsl_code: 1827)
    draft.update!(lgsl_code: 1827)
  end
end
