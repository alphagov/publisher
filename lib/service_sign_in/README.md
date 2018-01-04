# How to publish Service Sign In pages

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

# How to update Service Sign In pages

1. Follow the steps outlined [above](#how-to-publish-service-sign-in-pages).
2. If a `choose_sign_in` option text has changed, the page must be
[purged from the cache](https://docs.publishing.service.gov.uk/manual/cache-flush.html).
As the option text is parameterized to provide an option value for the radio
button, failing to purge the page for the cache will result in a mismatch
between the option value provided by the form and the option text in the content
item, resulting in a 500 error.
