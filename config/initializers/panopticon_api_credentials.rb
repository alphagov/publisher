# This file gets overwritten on deploy
PANOPTICON_API_CREDENTIALS = {
  :basic_auth => {
    :user     => ENV['PANOPTICAN_USER'],
    :password => ENV['PANOPTICAN_PASSWORD']
  }
}