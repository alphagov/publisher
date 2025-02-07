# ADR012 - Migrate MongoDB to PostgreSQL -  Schema/Object model design for Publisher on Postgres

Date 2025-02-05

## Status
Accepted

## Context
Move the Mainstream Publisher app from using MongoDB to PostgreSQL. This ADR is an outcome from the options captured in the [RFC](https://docs.google.com/document/d/1VwKxpRB4_YG7y__M-qTdAWrL8eGd7MZLu1cAO63lZwI/edit?pli=1&tab=t.0#heading=h.fk845ekgg28e) and the decision we made.

### Problem statement
- We have captured some drawbacks of using MongoDB for Mainstream Publisher in an ADR [here](https://docs.publishing.service.gov.uk/repos/publisher/arch/adr-009-replace-mongodb-with-postgres.html).
- Most of our publisher apps are on PostgreSQL or MySQL(in case of whitehall) and recently we moved the content-store app away from MongoDB; please find the RFC [here](https://github.com/alphagov/govuk-rfcs/pull/158/files).

#### Option 1 : [Delegated Types](https://guides.rubyonrails.org/v7.1/association_basics.html#delegated-types)
##### Database schema
There will be an edition table that will have columns for all of the attributes common to all content types, as well as columns to store the ‘Type’ for the delegated type (‘AnswerEdition’, ‘GuideEdition’, etc.) and the ‘ID’ from the record in the table of the delegated type. There will also be a separate table for each content type, containing columns that are only relevant to that content type, for example, the guide_edition and answer_edition tables will contain columns relevant to Guide and Answer content types, respectively, whereas the edition table will contain attributes that are common to both.

##### Example database schema
![Delegated Type schema](/docs/images/adr-012-delegated-types-db-schema.png)

##### Ruby model
The Edition model will have reference to all the delegated types, validations on all of the common attributes and all common methods. There will be a delegatable module, which can be included in all the content type models. All the content type models will have only those methods relevant to that specific content type.

##### Advantages
1. Represents a schema closest to the existing schema, thus reducing the changes needed to the models.
2. Avoids duplication of common attributes in the database tables for different content types (when compared to the second option).
3. Possibly fewer code changes, by defining delegates and using polymorphism on the  subclasses (this has not been explored in the spike). Refer to the [example from the Rails guide](https://guides.rubyonrails.org/v7.1/association_basics.html#adding-further-delegation).

##### Disadvantages
1. Can bloat the edition model class with delegates though we might be able to reduce that by moving delegates to a separate concern.
2. Having some methods on the Edition model and others on the delegated type (AnswerEdition, GuideEdition, etc.) could be unwieldy for consumers. For example, to access the body of an AnswerEdition stored in a variable `answer` consumers would need to write `answer.answer.body`. This can be made easier by using Active Support’s [method delegation](https://guides.rubyonrails.org/active_support_core_extensions.html#method-delegation), but that impacts the readability of the Edition class.
3. FactoryBot factories will have to be updated to make sure they create edition models with correct delegated types.

#### Option 2: Completely separate tables and models
We create separate tables for all of the content types, we no longer have an edition table or any parent table to store common fields. Each content type table contains all the fields it needs.

##### Database schema
All content types will have all the fields they need, the edition table would not exist.

##### Example database schema:
![Separate tables schema](/docs/images/adr-012-separate-db-schema.png)

##### Ruby model
All models for content types will remain mostly as-is, the edition model will be removed and we will introduce a new module which will have all the properties which are common between content types, this module can then be included in each of the content type models.

##### Advantages
1. Relatively few changes to test and factory files (compared to option 1).
2. Simplifies the database structure by denormalising it.

##### Disadvantages
1. Duplication of database columns.
2. Different to our existing schema pattern.
3. Makes it difficult to query and filter through all content types, for example, when listing all content items on the publications page. With the existing model structure, if we want to fetch all editions we can simply do `Edition.all` and then apply any filter logic to it, whereas if we denormalise the database, we will have to query through all the content item tables and then collect them into some sort of collection in order to be able to run any filter queries.

#### Option 3: Using JSONB field in the database to store

##### Database schema
In this approach we create a single edition table. The edition table will have all the columns that are common to all content types with another column of type JSONB which stores content type specific data in a json format.

##### Note
We tried to test this approach with `GuideEdition` which has a nested model `Parts` within it. It became difficult to structure the code to do this (having to convert to/from json).

##### Advantages
This option would have simplified the schema structure and would have allowed us to use the `Edition` table as a single table for all editions. All the content types would simply be stored in the form of json and could be validated through a schema file. This approach would be similar to what Publishing API does and would probably make most sense in the long run.

##### Disadvantage
This would require a lot more code changes than either of the other two options listed above.

#### Things we considered but decided not to pursue
1. Single table inheritance (STI), with a single edition table containing all fields for all content types.

##### Reason
STI works best when there is little difference between subclasses and their attributes but in our case, the attributes in different classes do vary and that makes an STI approach not so desirable.

## Decision
We would be taking the approach of using delegated types explained as option 1, given its advantage of being closest to the existing schema and relatively minimal code changes.
