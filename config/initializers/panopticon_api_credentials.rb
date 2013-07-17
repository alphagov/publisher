# This file gets overwritten on deploy
PANOPTICON_API_CREDENTIALS = {
  :basic_auth => {
    :user     => ENV['PANOPTICON_USER'],
    :password => ENV['PANOPTICON_PASSWORD']
  }
}