# Decision record: Why Service sign in pages aren't linked to from transaction pages using a content id

## Context
Currently, when content designers create a transaction page they enter a URL for
the service that the start button should link to, and this service is usually an
external (to GOV.UK) URL.  Service sign in pages however will be GOV.UK content
items, and ideally we should not link to specific content item URLs as they could
change in future.  Instead, the links should reference a content_id, which never
changes.  However as the field where content designers enter the URL that the
start button should link to doesn't support content_ids currently, the only
option available to them is to enter the URL for the service sign in page.

## Decision
After discussing this with @kevindew from the publishing platform team, we
identified that the risk of things breaking because we're linking directly to a
URL is quite low because if the base_path of the service sign in page changes,
the publishing API will automatically create a redirect.

## Consequences
Ideally we should ensure that we're referencing the content_id instead of the
service sign in page URL so that all risk is mitigated, so in future we should
look at how we can support providing a content_id instead of a URL on the edit
transaction page in Publisher.
