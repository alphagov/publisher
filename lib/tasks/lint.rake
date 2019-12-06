desc "Run govuk-lint with similar params to CI"
task lint: :environment do
  sh "bundle exec rubocop --format clang app test lib config"
end
