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

The current up-to-date version of GOV.UK Docker has been noted to have some compatibility issues with Publisher. For a known working version, after cloning the govuk-docker repository run:

```shell
git checkout 1b19821
```

### Setting up Publisher
**You will need the [GDS CLI installed and configured](https://docs.publishing.service.gov.uk/manual/get-started.html#7-install-and-configure-the-gds-cli) for these instructions.**

You can use GOV.UK Docker to run Publisher locally in your web browser. Some additional setup is required to populate the database and properly connect to the Publishing API for features such as tagging.

After following the instructions above to set up GOV.UK Docker, navigate to `~/govuk/govuk-docker` and then pull and build Publisher and all its dependencies using:
```sh
make publisher
```
This step only needs doing once, after this it will pick up changes to your local branches.

### Publisher Local Database

While not essential for local operation, it can be useful to download a copy of the Publisher Integration database which is pre-populated with test users and artefacts.

Still in the `~/govuk/govuk-docker` folder, run:

```sh
govuk-docker run publisher-lite bundle exec rake db:drop 
``` 
(optional, but recommended if you're not working from a blank slate)
```sh
govuk-docker run publisher-lite bundle exec rake db:setup
``` 
```sh
gds-cli aws govuk-integration-developer ./bin/replicate-mongodb.sh publisher
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
With both databases set up, the app can now be run locally using:
```sh
govuk-docker up publisher-app
```
You can now access your local Publisher at http://publisher.dev.gov.uk/
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

Publisher stores its data in DocumentDB, which can't be queried using the instructions detailed in the GOV.UK developer docs. Instead, follow [these instructions for querying the database](docs/database-querying.md). 

### Feature flags

For details on how feature flags are managed in Publisher, see the [feature flags documentation](docs/feature-flags.md).

### Adding promotions to Completed Transactions

For instructions on how to add a new type of promotion to Completed Transactions, see the ["adding a promotion" documentation](docs/adding-a-promotion-to-a-completed-transaction.md).

## Further documentation

- [Fact Checking](docs/fact-checking.md)

### Working with Service Sign In pages

These pages do not have an admin interface and are instead managed through rake tasks.

See the [README](lib/service_sign_in/README.md) for more details.

## Licence

[MIT License](LICENCE)
