## Adding new promotions to Completed Transactions

Completed Transactions have a concept of "promotions". These are simple call-outs that are shown on the page by the rendering app ([Feedback](https://github.com/alphagov/feedback)). The text displayed is not configurable within Mainstream Publisher, but is set in the rendering app.

To make a new type of promotion available when editing Completed Transactions, there are two parts:

1. Configuring the text displayed in Feedback.
2. Adding the promotion to Mainstream Publisher.

The text should be added to the Feedback app first, to avoid the possibility of someone attempting to add the new promotion to a Completed Transaction before Feedback knows how to render it (which would result in the Completed Transaction page not rendering, and an error being shown to the user).

### Configuring the text displayed in Feedback

The text shown for a promotion is controlled by the Feedback app, in a couple of configuration files (one for English text, and one for Welsh text). You can see an example from [the changes that added the promotion for bringing photo ID when voting](https://github.com/alphagov/feedback/pull/1834/files).

### Adding the promotion to Mainstream Publisher

There are a few code changes required to Mainstream Publisher when adding a promotion. You can see an example from [the changes that added the promotion for bringing photo ID when voting](https://github.com/alphagov/publisher/pull/2117/files).
