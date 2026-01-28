# ADR-014 - Migrate fact check handling to a Google OAuth based system

Date 2025-04-30

## Status
Draft

## Context
Google has [removed the ability](https://workspaceupdates.googleblog.com/2023/09/winding-down-google-sync-and-less-secure-apps-support.html) to log into google applications via the old insecure format of purely username and password, now relying on OAuth2 methods. This has broken fact check email functionality on Publisher, wherein we scan an email inbox to process incoming fact check requests for content on GOVUK.

### Problem statement
- Our existing mechanism no longer functions due to this change in security access by Google. This has broken well established behaviour in how we handle fact check requests for content published on GOVUK via Publisher.
- There is no way to bipass this change, so we need to consider other options to enable the existing fact check mechanism.
- The possible need to implement this behaviour inside Publisher without reliance on an external email tool is outside the scope of this ADR.
- Consideration towards the upcoming move to M365 is outside the scope of this ADR.

#### Option 1 : [App Passwords](https://support.google.com/accounts/answer/185833?hl=en)
##### In brief
An "app password" is a passcode that can be generated that bypasses the OAuth secure log in procedure and is designed explicitly for legacy application access to Google applications and services. We would create one for each of our three environment inboxes and tie that into the app via AWS Secrets Manager similar to how we do with the current password.

##### Advantages
- Enables access to our fact check email inboxes with minimal code changes
- Behaviour is otherwise 1:1 with the current implementation.

##### Disadvantages
- 2FA must be enabled on the associated accounts. 
     - This means that only one person can manually log into the email system as 2FA will be linked to a device or account belonging to that person. 
     - This prevents the team from readily accessing the email inbox in cases where it is needed, especially when the person responsible for the 2FA device is unavailable.
- Google recommends against this style of access, and it is unknown if this access will eventually be revoked.


#### Option 2: [Google Service Accounts](https://cloud.google.com/iam/docs/service-account-overview)
##### In brief
Google service accounts are build for application and compute access to google apps. We would replace our current system with calls to a service account based on the environment we are in, which in turn would give us access to the associated emails.

We would need to change gems to use the [google-api-client](https://github.com/googleapis/google-api-ruby-client/tree/main) gem for GMail, but it will give us a much more secure means of accessing the email than previously while keeping functionality intact and more future proof.

##### Implementation requirements

We would need to create three service accounts, one for each of our environments. These would be

- govuk-publisher-factcheck-integration
- govuk-publisher-factcheck-staging
- govuk-publisher-factcheck

Each service account as a unique ID and email, the latter of which can be truncated (e.g. govuk-publisher-factcheck-inte@govuk-integration.iam.gserviceaccount.com).

Each service account can generate a unique key for access via the API client gem mentioned above. These can be stored in AWS Secrets.

Each service account would need to be given [delegated domain-wide authority](https://github.com/googleapis/google-api-ruby-client/blob/1d1263b8757dc4a03926d2ae55711f00c7e244ed/docs/oauth-server.md#delegating-domain-wide-authority-to-the-service-account) for the GOVUK domain so it can access the required inboxes.

In giving this domain access we would need to give it access to the following API scopes:
-  https://www.googleapis.com/auth/gmail.labels
    - Such that we can change the labels on emails for correct classification as handled by the Publisher app.
- https://www.googleapis.com/auth/gmail.metadata,
    - So we can read deep data on each email we recieve beyond title and content.
- https://www.googleapis.com/auth/gmail.modify
    - To enable us to archive emails once handled. We cannot simply have read access.

The above API scopes enable the exact, 1:1 behaviour we currently rely on in the original Publisher implementation.

##### Advantages
- Google's preferred way of handling application access with no sign of support ending.
- Could potentially fix issues we have seen with emails not being processed correctly by Publisher due to a deeper handling of the content.
- Won't need any changes in how we handle the emails once we have accessed them.


##### Disadvantages
- Delegated domain wide authority carries a minor security risk due to it being a GSuite admin level flag.
- Will need to liase with IT as we don't have GSuite admin access.
- We cannot easily rely on existing code for handling the emails and we may have to drop the Mail gem causing headaches.


## Decision
Due to the 2FA limitation of, and Googles reluctance to support, app passwords, we will be implementing the service account method to handle emails. This is the most sensible, future proof way to upgrade Publisher that may make it easier to migrate to M365 in the future (though it is out of scope here) if we decide not to implement our own internal fact check replacement.
