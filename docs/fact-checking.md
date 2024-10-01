# Fact Checking

Publisher comes with a system to allow editions not yet published to be externally fact checked.

## Process

1. When a content designer clicks the "Fact check" button on an edition, they are presented with a form allowing them to input the email addresses they would like the fact check request to go to.
1. The fact checker who receives the email then reviews the draft version of the edition, and once happy, replies to the email with the review.
1. The email arrives in a Gmail inbox. Details of which inbox can be found in secrets under `govuk::apps::publisher::fact_check_username` and `govuk::apps::publisher::fact_check_password`.
1. Every 5 minutes, the [mail_fetcher](../script/mail_fetcher) script runs which reads any new emails from the inbox, parses the response and adds it to the edition in the database.

**Note:** The ID of the edition is included in the subject line of the fact check email. It's important that this is never removed, otherwise the app will be [unable to match the email with the edition](https://docs.publishing.service.gov.uk/manual/alerts/publisher-unprocessed-fact-check-emails.html).

**Information:** Sometimes fact check emails will fail to be processed. We use Prometheus to report this, and you can see how many are currently in the production fact-check inbox using [this grafana page](https://grafana.eks.production.govuk.digital/explore?schemaVersion=1&panes=%7B%22fj9%22%3A%7B%22datasource%22%3A%22prometheus%22%2C%22queries%22%3A%5B%7B%22refId%22%3A%22A%22%2C%22expr%22%3A%22publisher_fact_check_unprocessed_emails_total%22%2C%22range%22%3Atrue%2C%22instant%22%3Atrue%2C%22datasource%22%3A%7B%22type%22%3A%22prometheus%22%2C%22uid%22%3A%22prometheus%22%7D%2C%22editorMode%22%3A%22code%22%2C%22legendFormat%22%3A%22unprocessed_emails%22%7D%5D%2C%22range%22%3A%7B%22from%22%3A%22now-30d%22%2C%22to%22%3A%22now%22%7D%7D%7D&orgId=1).
