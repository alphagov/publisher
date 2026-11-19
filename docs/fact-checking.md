# Fact Checking

Publisher comes with a system to allow editions not yet published to be externally fact checked.

## Process

1. When a content designer clicks the "Fact check" button on an edition, they are presented with a form allowing them to input the email addresses they would like the fact check request to go to. 
1. Upon sending this email, a comparison age is generated in Fact Check Manager via the API.
1. The email contains a link to the comparison page in Fact Check Manager showing the content of the previous and current versions in a comparison view.
1. If the user has signon permissions to respond, the user follows the steps in Fact Check Manager to either indicate that the changes are correct, or indicate the changes are incorrect with a comment.
1. When that fact check is sent, Publisher recieves an API request from Fact Check Manager that updates the status of the edition with the response, either positive or negative, and any relevant note.

**Note:** Due to security requirements we need to manually reset the edition's `auth_bypass_id` and thus invalidate existing preview links at this stage. We can do this by supplying a comma separated list of quote edition IDs to the [associated rake task](https://github.com/alphagov/publisher/pull/3284/changes#diff-84ce051a6ca45ebf2ca70242f2b143f331c43aeb926b4344c862b68a425e3ac4R2). For example `fact_check:revoke_and_renew_draft_links["edition_id1","edition_id2"]`
