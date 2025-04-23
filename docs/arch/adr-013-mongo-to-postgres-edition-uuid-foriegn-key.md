# ADR013 - MongoDB to PostgreSQL -  Edition id to be UUID instead of autoincrement BigInt and a column to store old mongo id

## Date 2025-04-23

## Status
Accepted

## Context
1.  During code migration for fact check, we understood that it might not be a great idea to keep simple numeric id of editions in fact check emails as it makes it very easy to maliciously, or accidentally change the id and fact check the wrong edition. In order to avoid these unintended consequences from having a simple numeric id, we want to make the edition id to be UUID.
2.  We want to introduce a new column [mongo_id] in postgres table, this is to store the corresponding mongo id for each existing edition for two reasons,
     *  if some of the editions are already out for fact check between migrations, we can check their mongo id and then update history and notes.
     *  This allows a to have a backup and allows us to correlate editions in mongo and postgres.

## How this would be implemented :
To implement this, we need to write migration to use UUID as primary key, this is [explained here](https://guides.rubyonrails.org/v5.0/active_record_postgresql.html#uuid-primary-keys) and an example of this in alphagov is an [implementation in govuk-chat](https://github.com/alphagov/govuk-chat/blob/74a865bea991d0fa7de56ef255051df7176079fb/db/schema.rb#L47C61-L47C76).

## Consequences
The only notable consequence of this would be the ids in edition urls and fact check email’s subject would look different. The current id is a 12-byte ObjectId and a UUID is 16 bytes, arranged in 5 groups separated by hyphens, namely 8–4–4–4–12, totaling 36 characters (32 alphanumeric characters and 4 hyphens).

Example of an existing edition id : 653e33d76187a0001afaf021
Example of a UUID : 8ca0fd81-fd03-438c-8730-c6c4e7ef4aa9
