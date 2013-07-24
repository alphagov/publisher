# This file gets overwritten on deploy
if Rails.env.test?
  PANOPTICON_API_CREDENTIALS = {}
else
  PANOPTICON_API_CREDENTIALS = {
    :basic_auth => {
      :user     => ENV['PANOPTICON_USER'] || "api",
      :password => ENV['PANOPTICON_PASSWORD'] || "defined_on_rollout_not"
    }
  }
end
