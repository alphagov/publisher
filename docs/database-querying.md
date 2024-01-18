## Querying the database

Publisher uses MongoDB for its data storage (technically, it only uses MongoDB when running locally—on AWS it uses DocumentDB, which is "Mongo-compatible"). There are two ways of querying the data stored in the database:
1. using [Mongoid](https://www.mongodb.com/docs/mongoid/current/)
2. using a Mongo shell.

The GOV.UK developer docs document [how to open a database command-line session](https://docs.publishing.service.gov.uk/manual/databases.html#open-a-database-commmand-line-session) of a Rails application deployed to k8s, but this doesn't work for Publisher, as attempting to run the specified command results in an exception.

To query the database, first [establish access to the k8s cluster](https://docs.publishing.service.gov.uk/kubernetes/get-started/access-eks-cluster/#access-a-cluster-that-you-have-accessed-before), then [open a rails console](https://docs.publishing.service.gov.uk/kubernetes/cheatsheet.html#open-a-rails-console) on one of the publisher pods.

### Querying using Mongoid

Mongoid is "the officially supported object-document mapper (ODM) for MongoDB in Ruby". It can be used to query the database using Rails models.

From within the Rails console, query the data using [Mongoid](https://www.mongodb.com/docs/mongoid/current/reference/queries/). For example:

```shell
Edition.first
=> #<GuideEdition _id: ...>
```
returns the first edition in the database, as a Rails model object.

### Querying using a Mongo shell

One thing to be aware of with this technique, is that Publisher's database is actually shared with other apps, so there is data within it that does not belong to Publisher—don't be surprised when querying if you see collections that you don't recognise.

From within the Rails console, query the data using the Mongo shell:

```ruby
client = Mongo::Client.new(ENV["MONGODB_URI"])
db = client.database

db.collection_names
=>
  ["artefacts",
    ...
  ]
```
