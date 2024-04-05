# ADR009 - Replace MongoDb with Postgres

Date 2024-04-03

## Status
Accepted

## Context

Publisher uses MongoDb for persistence and we use Amazon DocumentDB in our deployed environments. As described by Amazon, 
```Amazon DocumentDB (with MongoDB compatibility) is a fast, scalable, highly available, and fully managed document database service that supports MongoDB workloads.```

As there's no docker image available to support local development with DocumentDB we use the official mongo docker image locally and in the CI pipelines and connect to DocumentDB once deployed to Integration. We use standard Mongo features which are supported by DocumentDB so we don't usually experience any issues. When we have experienced issues they've been severe and time consuming to diagnose;

- A bug in a mongo driver update surfaced once connecting to DocumentDB and not in any of the unit tests, integration or smokey tests. It caused publisher to fail in production, resulting in a P3. Identifying the issue and attempting to set up a fast feedback environment to verify and experiment with it became quite a drain on our focus for more than a few weeks.
- Certain searches within publisher were failing due to hitting a proxy timeout of 15 seconds. Locally the searches were an order of magnitude quicker with the same data. Upon further investigation this was due to DocumentDB behaving slightly differently to Mongo in terms of the query strategy and which indexes to use.

Though not the primary motive to switch, a document database isn't a great fit for publisher - based on the data model and usage patterns. 

Another influence in the decision is the longer term strategic goal of having an easier to maintain set of apps on a consistent platform.

Considering the impact of the issues already experienced on team time along with the fact that less and less of the estate is going to be using DocumentDB gives us reason and motivation to make the change. 

## Decision
We will migrate the database publisher uses from Mongo to Postgres and migrate the data from DocumentDB to RDS.

## Consequences
- Performance characteristics will differ. We will need to base-line current performance and track the effect of the change. 
- The application will be unavailable for a period of time in each environment as we migrate - that period being at least the 
time required to export current data and import to the new datasource.

