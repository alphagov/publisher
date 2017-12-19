# How to publish Service Sign-in pages

If a Content Designer adds a new page via Github, there's a good chance they'll be an external contributor.

See [How to merge a change from an external contributor](https://docs.publishing.service.gov.uk/manual/howto-merge-a-pull-request-from-an-external-contributor.html) in the developer docs

The examples below are from a [release from the Start Pages team](https://github.com/alphagov/publisher/pull/687)

## Releasing the new page

Once the change is merged, you can release these in two steps.

1. [Deploy publisher](https://docs.publishing.service.gov.uk/manual/deploying.html)
2. Run the Rake task to publish the new page

### Running the Rake task

Go to the [Jenkins Rake task job (Staging)](https://deploy.staging.publishing.service.gov.uk/job/run-rake-task/parambuild/?TARGET_APPLICATION=publisher&MACHINE_CLASS=backend&RAKE_TASK=service_sign_in:publish[check-update-company-car-tax.en.yaml]) ([Production](https://deploy.publishing.service.gov.uk/job/run-rake-task/parambuild/?TARGET_APPLICATION=publisher&MACHINE_CLASS=backend&RAKE_TASK=service_sign_in:publish[check-update-company-car-tax.en.yaml]))


Run the task with the following parameters

| Field              | Value                                                         |
|--------------------|---------------------------------------------------------------|
| TARGET_APPLICATION | publisher                                                     |
| MACHINE_CLASS      | backend                                                       |
| RAKE_TASK          | service_sign_in:publish[check-update-company-car-tax.en.yaml] |
