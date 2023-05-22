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

**Use GOV.UK Docker to run any commands that follow.**

### Testing

The default `rake` task runs all the tests:

```sh
bundle exec rake
```

### State machine

Maps out the transitions between states for the `Edition` class. These transitions are defined in the [workflow](app/models/workflow.rb) module.
A diagram of the current state machine can be seen here: [state machine diagram](docs/state_machines/state_machine_diagram_for_edition.png).
The diagram can be (re)generated using the [state_machines-graphviz gem](https://github.com/state-machines/state_machines-graphviz), by doing:

```sh
bundle exec rake state_machines:draw CLASS=Edition TARGET=docs
```

This will generate a diagram in the `docs/state_machines` folder.

## Further documentation

- [Fact Checking](docs/fact-checking.md)

### Working with Service Sign In pages

These pages do not have an admin interface and are instead managed through rake tasks.

See the [README](lib/service_sign_in/README.md) for more details.

## Licence

[MIT License](LICENCE)
