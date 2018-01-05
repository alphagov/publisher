# Decision record: Rendering Service Sign In pages using Government Frontend

## Context
As Service Sign In is a new format, we needed to decide how to render it.

## Decision
We had a few options when deciding where this format should be rendered from.
Firstly we considered building a new rendering app, however quickly ruled this
out as the content wasn't expected to be radically different to existing
content, so building a new rendering app specifically for it seemed like
overkill.

Next we looked at rendering the content from Frontend, and some existing
Publisher formats are rendered from it and it already handles some page
interaction. However there is technical debt associated with Frontend and some
Publisher formats have been migrated to Government Frontend, so it seemed
counterproductive to render Service Sign In pages from Frontend only for that to
be changed at some point in the future.

Finally we looked at using Government Frontend, which many formats have migrated
to using. Currently Government Frontend is only concerned with read-only content
such as documents, and doesn't handle interactive content. While we would be
allowing Government Frontend to handle more complex content, we didn't feel that
this would be making the app itself more complicated. Given that Government
Frontend has a more certain future than Frontend, this seemed like the right
rendering app for this new format.

## Consequences
We have had to add a radio button component to Government Frontend, which
introduces interaction to to the app.
