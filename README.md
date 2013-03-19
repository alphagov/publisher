# Publisher

Publisher is the primary content design app for GovUK. It provides the user interface for
entering all the key editorial formats and an API so other apps (primarily frontend) can
access that data for display. It is intended to work in partnership with Panopticon which
manages metadata, slugs, titles, etc.

## Running in development

If you're just interested in running the Publisher locally, with a minimum of interaction
with other apps, here's how.

*These instructions are out of date. Updates coming soon*

### Create a user

    publisher$ script/console
    >> User.create name: "Your name", email: "youremail@example.com", uid: Time.zone.now.to_i, version: 1

### Run panopticon using rails s or similar

    panopticon$ rails s -p 3001

### Run the publisher app setting env variable to point at your panopticon instance

    publisher$ PANOPTICON_URI="http://localhost:3001" bundle exec rails server

## Local Transactions

There is no UI or automated process for importing the source data for local transactions.

The source data can be downloaded from [http://local.direct.gov.uk/Data/local_authority_service_details.CSV](DirectGov).

They can be imported using a rake task:

    bundle exec rake local_transactions:import SOURCE=/path/to/local_authority_service_details.CSV

## Statsd

This application uses [statsd-ruby](http://rubygems.org/gems/statsd-ruby) to send metrics to
[statsd](https://github.com/etsy/statsd/). If a statsd process isn't present on the server
it won't matter as statsd-ruby sends metrics over UDP. If a statsd process is present then
it'll send strings with the respective increment/decrement/gauge function to use.
