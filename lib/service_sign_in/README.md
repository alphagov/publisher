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

# How to unpublish Service Sign In pages

1. Find the `content_id` and `locale` of the page you would like to unpublish.

2. Go to the Jenkins Rake task job on  [Staging](https://deploy.staging.publishing.service.gov.uk/job/run-rake-task/build?delay=0sec) or [Production](https://deploy.publishing.service.gov.uk/job/run-rake-task/build?delay=0sec)

There are two ways to unpublish a Service Sign In Page; with a redirect, and without a redirect (410 gone).

## Unpublishing with a redirect

3. Run the task with the following parameters, replacing the content-id, locale and /redirect/path with your own values.

| Field              | Value                                                                     |
|--------------------|---------------------------------------------------------------------------|
| TARGET_APPLICATION | publisher                                                                 |
| MACHINE_CLASS      | backend                                                                   |
| RAKE_TASK          | service_sign_in:unpublish_with_redirect[content-id,locale,/redirect/path] |

## Unpublishing without a redirect

3. Run the task with the following parameters, replacing the content-id and locale with your own values.

| Field              | Value                                                                     |
|--------------------|---------------------------------------------------------------------------|
| TARGET_APPLICATION | publisher                                                                 |
| MACHINE_CLASS      | backend                                                                   |
| RAKE_TASK          | service_sign_in:unpublish_without_redirect[content-id,locale]             |
