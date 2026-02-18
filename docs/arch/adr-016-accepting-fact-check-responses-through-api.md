# ADR015 Accepting Fact Check responses through API

## Date 2026-02-17

## Status
Accepted

## Context

The current state machine flow in publisher is built around use of the User class, most state transitions are eventually run through the User#progress method.

As receiving fact check responses happens asynchronously using a mail fetcher script, this has to be handled with a workaround where a User object is initiated, used to run the command, and then never saved. This results in an Action without a user attached, and some fallback code in the History and Notes tab adds in the "GOV.UK Bot" user name.

## Decision

Three main options were considered for a solution:

- A) Do nothing, continue to use the current flow with the throwaway User instance and "GOV.UK Bot" identifier.
- B) Use the information we hold in Fact Check Manager to create a dummy user, save it to the Users table, and use this to run the state change instead.
- C) Continue using the throwaway User instance to run the state change. Add a new "requester_name" attribute to the Action model and use this to store and display the SPOCs name in History and Notes.

Option C was chosen.

## Considerations

- Option B would have worked but would have muddied the Publisher data flow more, as we would have entries in the Users table that were not valid Publisher users.
- Actions model has several other attributes carrying state-specific information like this.
- Retrieving user details from signon was considered, but this would have prevented phase 2 plans to allow SPOCs to authenticate via magic links.

## Consequences

- Positive: Minimal change to existing flow, SPOC name can be displayed in History and Notes rather than static "GOV.UK Bot"
- Trade-offs: One extra attribute in Action objects
