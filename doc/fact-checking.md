# Fact Checking

Publisher comes with a system to allow editions not yet published to be externally fact checked.

## Process

1. When a content designer clicks the "Fact check" button on an edition, they are presented with a form allowing them to input the email addresses they would like the fact check request to go to.
1. The fact checker who receives the email then reviews the draft version of the edition, and once happy, replies to the email with the review.
1. The email arrives in a Gmail inbox. Details of which inbox can be found in secrets under `govuk::apps::publisher::fact_check_username` and `govuk::apps::publisher::fact_check_password`.
1. Every 5 minutes, the [mail_fetcher](../script/mail_fetcher) script runs which reads any new emails from the inbox, parses the response and adds it to the edition in the database.

**Note:** The ID of the edition is included in the subject line of the fact check email. It's important that this is never removed, otherwise the app will be [unable to match the email with the edition](https://docs.publishing.service.gov.uk/manual/alerts/publisher-unprocessed-fact-check-emails.html).
