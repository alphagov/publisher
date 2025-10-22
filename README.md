# Publisher

Publisher is sometimes referred to as "mainstream publisher".

## Live examples
- [Answer](https://www.gov.uk/smart-meters)
- [Completed transaction](https://www.gov.uk/done/make-lpa)
- [Guide](https://www.gov.uk/council-tax-appeals)
- [Help page](https://www.gov.uk/help/accessibility)
- [Local transactions](https://www.gov.uk/complain-about-your-council)
- [Place](https://www.gov.uk/ukonline-centre-internet-access-computer-training)
- [Service sign in](https://www.gov.uk/log-in-file-self-assessment-tax-return/sign-in)
- [Simple smart answer](https://www.gov.uk/qualify-tax-credits)
- [Transaction](https://www.gov.uk/council-tax-bands)

## Retired formats
- Campaign
- Programme
- Video
- Licence (Migrated to Specialist Licence Finder)

## Removed formats
- Business Support - used to be retired, and the documents remained visible, now
  they're fully removed as editions and no longer visible in the app (although
  the artefacts do still exist).  They have been fully migrated to
  specialist-publisher.

## Nomenclature

- **Artefact**: a document on GOV.UK.

## Technical documentation

This is a Rails application and should follow [our Rails app conventions](https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html).

You can use the [GOV.UK Docker environment](https://github.com/alphagov/govuk-docker) to run the application and its tests with all the necessary dependencies.  Follow [the usage instructions](https://github.com/alphagov/govuk-docker#usage) to get started.

### Setting up Publisher
**You will need the [GDS CLI installed and configured](https://docs.publishing.service.gov.uk/manual/get-started.html#7-install-and-configure-the-gds-cli) for these instructions.**

You can use GOV.UK Docker to run Publisher locally in your web browser. Some additional setup is required to populate the database and properly connect to the Publishing API for features such as tagging.

After following the instructions above to set up GOV.UK Docker, navigate to `~/govuk/govuk-docker` and then pull and build Publisher and all its dependencies using:
```sh
make publisher
```
This step only needs doing once, after this it will pick up changes to your local branches. Re-running this command can be a useful way to wipe your local Publisher container and start fresh if it ends up in a corrupted state.

At this point your local Publisher will be functional, but with no data populated in its database.

### Publisher Local Database

While not essential for local operation, it can be useful to download a copy of the Publisher Integration database which is pre-populated with test users and artefacts.

Still in the `~/govuk/govuk-docker` folder, run:

```sh
govuk-docker run publisher-lite bundle exec rake db:drop #(optional, but recommended if you're not working from a blank slate) 
``` 

```sh
govuk-docker run publisher-lite bundle exec rake db:setup
``` 
```sh
gds-cli aws govuk-integration-developer --assume-role-ttl 3h ./bin/replicate-postgresql.sh publisher
``` 

The test user `James Stewart` does not have any permissions by default, so you will need to add them. Open the rails console with:
```sh
govuk-docker run publisher-lite bundle exec rails c
 ```
And then run:

```ruby
u = User.first
```
```ruby
u.permissions.append("govuk_editor", "skip_review", "welsh_editor")
```
```ruby
u.save
```
and finally `exit` out of the console.

### Setting up Publishing API (Optional)
The steps already done will enable most of Publisher's functionality locally. Some features such as tagging also require Publishing API to have a fully populated database.

To set this up, first go into your Docker settings and under Resources increase the disk usage maximum limit. The default 128 GB is not enough to properly run both Publisher and Publishing API. 

Increasing the CPU and Memory limits is also recommended to make the resource heavy processing steps quicker. Memory and CPU can be reduced if needed once everything is set up.

Make sure that you're still in the `~/govuk/govuk-docker` folder and, similarly to Publisher, run:

```sh
govuk-docker run publishing-api-lite bundle exec rake db:drop 
```
```sh
govuk-docker run publishing-api-lite bundle exec rake db:setup
``` 
```sh
gds-cli aws govuk-integration-developer ./bin/replicate-postgresql.sh publishing-api
``` 
The file for Publishing API is significantly larger than the one for Publisher (approx 70 GB). Depending on your internet connection, it will likely take over an hour to download, and slightly longer than that again to install.

While the database is building after the download, the shell output for that step isn't fully accurate. It will reach 100%, and then appear to hang in the terminal. Looking directly at the logs in the `govuk-docker` postgres container will show it still working. Be patient, and the process will eventually  finish and exit on its own.

If you experience an interruption during this process, your database will be left in a corrupted state. If this happens, re-run the `rake db:drop` and `rake db:setup` steps followed by the `replicate-postgresql` command above. It will re-use the already downloaded dump file rather than re-download it.

### Running Locally
The app can be run locally using:
```sh
govuk-docker up publisher-app
```
And then visiting http://publisher.dev.gov.uk/ in your web browser. The terminal you use to run the command will display useful server activity logs for debugging. Make sure to use `control + c` to gracefully shut down the server when you're done with it.

### Unable to load server locally
Sometimes the above command will fail with the message `A server is already running.` This usually happens when the local server is not shut down gracefully.

To fix this load up the docker container directly in a shell session
```sh
govuk-docker run publisher-lite bash
```
Now navigate to `~/publisher/tmp/pids` and delete the file inside using `rm`.

If this has happened to Publisher it has likely happened to your local versions of other supporting applications, such as Signon and Publishing API. The same instructions can be used to get those working again.

### Testing

The default `rake` task runs all the tests:

```sh
govuk-docker run publisher-lite bundle exec rake
```

### State machine

Maps out the transitions between states for the `Edition` class. These transitions are defined in the [workflow](app/models/workflow.rb) module.
A diagram of the current state machine can be seen here: [state machine diagram](docs/state_machines/state_machine_diagram_for_edition.png).
The diagram can be (re)generated using the [state_machines-graphviz gem](https://github.com/state-machines/state_machines-graphviz), by doing:

```sh
govuk-docker run publisher-lite bundle exec rake state_machines:draw CLASS=Edition TARGET=docs
```

This will generate a diagram in the `docs/state_machines` folder.

### Querying the database of a deployed publisher app

Publisher stores its data in a PostgreSQL database. You can interact with the database by connecting to one of the Kubernetes pod and using the [Rails Console with ActiveRecord](https://guides.rubyonrails.org/active_record_querying.html), or you can query it directly with SQL commands by following [the instructions detailed in the GOV.UK developer docs](https://docs.publishing.service.gov.uk/manual/databases.html#open-a-database-commmand-line-session).

### Feature flags

For details on how feature flags are managed in Publisher, see the [feature flags documentation](docs/feature-flags.md).

### Adding promotions to Completed Transactions

For instructions on how to add a new type of promotion to Completed Transactions, see the ["adding a promotion" documentation](docs/adding-a-promotion-to-a-completed-transaction.md).

## Further documentation

- [Fact Checking](docs/fact-checking.md)

## Licence

[MIT License](LICENCE)
