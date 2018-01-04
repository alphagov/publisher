# Decision record: Forking frontend components from GOV.UK Frontend

## Context
We needed to add radio buttons to Government Frontend so that users can make a
choice on the Service Sign In `choose_sign_in` page. The new
[GOV.UK Frontend](https://github.com/alphagov/govuk-frontend) project has a
component for radio buttons, as does [GOV.UK Elements](https://github.com/alphagov/govuk_elements),
so we needed to make a decision about which one to use.

## Decision
GOV.UK Elements is quite an old project that hasn't been kept up to date, and
there have been issues in the past where it has conflicted with existing CSS in
other GOV.UK projects. As such, the general recommendation is that [GOV.UK
Elements shouldn't be used](https://docs.google.com/document/d/1ZQ3qfMAdGQWIt5oklvKDhhGfYb-4bct75ZwVPUbnN2k/edit)
for new GOV.UK projects.

GOV.UK Frontend is expected to be the standard for future frontend work, and so
ideally any new components should be
[built to meet its conventions](https://docs.publishing.service.gov.uk/manual/components.html#building-components)
so that in future GOV.UK will be compatible with it. However, GOV.UK Frontend is
currently in alpha and not suitable for production use. In order to use it and
future-proof the frontend for this format, we forked the current alpha build of
GOV.UK Frontend and tested it ourselves before using in Government Frontend.
This has been done in such a way that files are isolated and can be updated to
use the GOV.UK Frontend project in the future, removing the need for our own CSS
and instead relying on the upstream.

## Consequences
As we are using a fork of GOV.UK Frontend we may not always be using the most
up-to-date version.
