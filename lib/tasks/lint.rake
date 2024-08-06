desc "Run all linters"
task lint: :environment do
  if Rails.env.development?
    sh "bundle exec erblint --lint-all --autocorrect"
  else
    sh "bundle exec erblint --lint-all"
  end
  sh "bundle exec rubocop"
  sh "yarn run lint"
end
