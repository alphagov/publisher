# Redirecting Parts after Format Change

Publisher supports parted editions - specifically Guides and Programmes. We also support the ability to change the format of these to one that does not support parts, such as Answers or Help Page.

When doing this "shrinking", all parts (including their titles) that are contained within the existing parted edition are combined into the body of the new unparted edition via the `whole_body` function in [Parted](../app/models/parted.rb).

In many cases, we have handling for this in the frontend apps such that a part is redirected to the slug if it no longer exists. However we have found that occasionally a format has been missed from this handling.

#### What to do

If the Publisher team recieves reports that a document that was previously a Parted type is not redirecting properly when converted to an Unparted type, ensure that the routes in the responsible renderer for that edition type includes the following line:

`get ":slug/:part", to: redirect("/%{slug}")`

You can find an example of this in [this commit](https://github.com/alphagov/frontend/commit/a659f16b38851839e24a36e234cd136583e2616f) for Frontend that handles this scenario for Answer pages.