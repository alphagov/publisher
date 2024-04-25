# ADR010 - Ensuring consistent edition state when unpublishing

Date 2024-04-25

## Status

Accepted

## Context

There is a need to ensure consistency in state between the Publishing API and the Mainstream Publisher database when unpublishing an edition. Unpublishing is also known as archiving. This is a form of distributed transaction.

There are a few options on how this can be achieved:
1. Using a database transaction.
2. Applying the change to the database, rolling back if the Publishing API returns an error.
3. Applying the change to the Publishing API and, if successful, then updating the database.

### Option 1: Use a database transaction

A common pattern for achieving this would be to create a transaction on the database and, based on the result on calling the Publishing API, either commiting or rolling back the transaction.

The version of Mongo that we are using (3.6) does not have transactions, instead applications have to replicate transactions by using two-phase commits. Version 4.0 does introduce transactions.

#### Disadvantages

- A fair amount of effort to implement two-phase commits.
- Would increase the complexity of the upcoming planned work to migrate to Postgres.

#### Advantages

- None

### Option 2: Rollback database change when error returned by Publishing API

The code currently applies the change to the database, and then calls the Publishing API. We could add some exception handling to the Publishing API call to then update the database again to undo the changes that were made.

#### Disadvantages

- Due to the version of MongoDB in use not supporting transactions, the changes made by the first update (before calling Publishing API) will be visible until the second update (to reverse the change) is made.
- It’s possible that the second database change (to rollback the first update) could fail, which would result in an inconsistent state, as it does at the moment.

#### Advantages

- Minimal change to the way that the code currently works.

#### Questions

Is the system designed to make forward “rollbacks” in this way (i.e. to change the state of an edition after it has been archived)?

### Option 3: Unpublish via the Publishing API first

Instead of updating Mainstream Publisher’s database first, and then calling the Publishing API, the order could be reversed to call the Publishing API first, and then update the database if, and only if, the response from the Publishing API is a success.

#### Disadvantages

- If the database update fails, the system will be in an inconsistent state (instead of the Publishing API being “out of date”, it will be Mainstream Publisher’s database that is “out of date”. The database update should be a lot more reliable than the call to the Publishing API, however (see advantages).

#### Advantages

- Least complex solution to implement.
- The database update is unlikely to fail, and so the opportunity to get into an inconsistent state should be much reduced in comparison to the current implementation.

## Decision

We will implement Option 3 (unpublishing via the Publishing API first), as this is the simplest implementation change and the only failure scenario is when the database update fails, which is unlikely to happen. Furthermore, if this does happen, it is only Mainstream Publisher that is out of date, the actual unpublishing desired by the user will have happened.

## Consequences
In the unlikely event that the database update fails, manual intervention will be required to unpublish the edition in Mainstream Publisher, to match the actual state in the Publishing API.
