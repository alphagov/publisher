# Decision record: Why "Service sign in" is its own format

## Context
The Q3 Start Pages mission goal was to make it easier for users to choose a sign
in option in order to access a service.  It was decided that a page should sit
in between the transaction/guide page and the service which allows users to
select a sign in option such as GOV.UK Verify or Government Gateway, or to
register for a new account (henceforth know as the service sign in page).

We initially looked at whether we could use an existing format to house this page.
At first glance, it felt that transaction pages might be a suitable place for
it, as it would be tailored to the transaction.  Alternatively we could create a
new format for this page.

## Decision
We ruled out incorporating service sign in pages into the transaction format for
a few reasons.  Firstly, we realised that service sign pages could also be
linked to from guides, as content designers sometimes embed start buttons in to
them, so including them in the transaction format only wouldn't be suitable for
guides.  Secondly, we felt that the scope of this mission did not include
consolidating any product debt around transactions, which would be required in
order to incorporate service sign pages, so it wasn't appropriate to follow this
route.  Additionally, we knew from the outset that building a UI to support
service sign in pages wasn't in scope for this mission, and in order to deliver
a decent user experience for content designers we would probably need to alter
the transaction UI.

In order to have the flexibility of linking to service sign
in pages from more than one format, and better handle the need for additional
pages related to service sign in (e.g. create new account page) we decided to
create a `service_sign_in` format.  We also made the decision that the format
should house up to two pages; a required `choose_sign_in` page which contains
the options that the user can choose from, and an optional `create_new_account`
page which allows users to make a decision about which account they should sign
up for.  We did consider creating a separate format for `create_new_account`
however we felt that at the current time there is no need for a standalone page
for this.

## Consequences
If we explored the user needs met by abusing the guide format, and consolidated
hacky usage of other formats into transactions to meet those needs, it may make
more sense to have a less flexible format or extension to transactions which
could potentially make the publisher workflow easier and allow consistent
iterations to start pages as a product.
