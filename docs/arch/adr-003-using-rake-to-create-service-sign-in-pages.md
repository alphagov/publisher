# Decision record: Why "Service sign in" pages are created using rake tasks

## Context
For the Q3 Start Pages mission, we descoped creating a UI in Publisher to handle
the workflow of managing Service sign in pages due to time constraints. As such
we needed to find a way for developers to easily create and update service sign
in pages.

## Decision
One of the options was to hardcode the content within their own views, which
would require a developer to manually update content when needed. While this is
a simple approach, it isn't very scalable and is prone to error. With this
approach we would not be sending the content to the Publishing API. As such we
would have to remember to register routes ourselves, and wouldn't have other
benefits of the Publishing API such as maintaining content history.

We knew that Smart Answers made use of rake tasks to import content, so we
considered following a similar approach. This would involve a content designer
providing a YAML file containing the content, which would be imported using a
rake task and then presented in a data format that could be sent to the
Publishing API. The downside of this approach is that we assume that content
designers have some level of familiarity with YAML and would be able to provide
the file to us via Git. However we felt that this would be the best approach as
a developer tasked with publishing a service sign in page in future would only
need to invoke a simple rake task instead of manually updating content
themselves. We've also provided an example YAML file so that content designers
are able follow a template and ensure that all the data is supplied in a
suitable format.

## Consequences
Due to no UI being provided to create a Service sign in page, the workflow is
unusual for content designers and as previously mentioned it does assume
familiarity with YAML and Git. While we expect most content designers will have
access to a developer who may be able to assist, we should acknowledge some
potential risk here.
