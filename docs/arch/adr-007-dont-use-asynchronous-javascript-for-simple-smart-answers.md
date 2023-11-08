# ADR007 – Don’t use asynchronous javascript for simple smart answers

Date 2023-11-06

## Status 
Accepted

## Context
There was some work to make the Mainstream publisher user interface more user friendly around 2015 by introducing an asynchronous post back mechanism that posted current edit state to the server without posting the page and requiring a page refresh.

This commit comment explains that at the time, Simple Smart Answers (SSA) was excluded from the work 
https://github.com/alphagov/publisher/pull/358/commits/74e4d135d9619cf799935b8ca2ea45cffc62f2d3

> **Don't save simple smart answers using ajax**. Javascript form construction is too complex to handle validation
without a full page reload, at least for now.

This has been revisited recently as users have requested the asynchronous postback feature to be added to Simple Smart Answers. 

Similar to Guides (which are made up of smaller components called Parts), SSA also need a separate module that handles its own smaller components (Nodes) more gracefully. This will allow us to use Snackbars with SSA and validations will be handled correctly in all parts of the SSA form, following current convention the module could be called ajax_save_with_nodes.js

It was decided that the effort to create a well tested ajax_save_with_nodes.js module for SSA, is not something we have capacity for within the team at this time. Although there is benefit for the users to have features such as Snackbars, there is a possibility that we may be moving Publisher over to the GDS Design System, where Javascript is not permitted, meaning Snackbars may end up being removed from publisher entirely, making the effort redundant. 

## Decision
We will not implement asynchronous javascript saves for the simple smart answers content type in publisher

## Consequences
- The Simple Smart Answers content type will continue to do a full post back on save
- Additional work that depends on the async postback will be archived, for example retaining scroll position on save

