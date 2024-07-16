# ADR011 - Restricting access to content by organisation

Date 2024-07-16

## Status

Accepted

## Context

Historically, access to Mainstream Publisher has been restricted to GDS content designers. There is a desire to open access up to content designers from other government departments, so that they can manage their own content in Mainstream Publisher, without them having access to all content.

In order to achieve this, a mechanism needs to be implemented whereby access to Mainstream Publisher does not automatically grant access to all content within Mainstream Publisher.

A limited number of content designers from HMRC have already been given access, and are being trusted not to edit content that they shouldn't. Before this access can be further widened, it's desired to have some form of restrictions in place within Mainstream Publisher. 

There is a wider piece of work looking at access and permissions across the Publishing estate, but access to Mainstream Publisher needs to be widened before that work will complete.

Therefore, we need an interim solution that restricts access within Mainstream Publisher to a subset of the content held within it, acknowledging that how this works might change longer-term.

In the immediate term, the requirement is to limit access, for non-GDS content designers, to that content which is managed by their own department. Signon does provide the organisation that a user belongs to, which Mainstream Publisher will use in order to make authorisation decisions when attempting to view and edit content. There are some cases where a content item would need to be managed by content designers from multiple organisations. 

For now the access rules for existing publications can be binary, with users either given full access to a piece of content (view/edit/publish), or no access.

There is a separate discussion to be had (outside the scope of this ADR) as to whether the ability to create new publications should be restricted. Currently, creating new publications ("artefacts") requires the "Editor" permission, but we might want to change this to enable non-GDS content designers to be able to create new publications without needing to have this permission (for example, by introducing a new permission for creating publications). 

This ADS focuses on the technical solution to restrict access, using the data supplied by Signon about the user (i.e. the organisation to which they belong).

### Option 1: Use the primary publishing organisation

All content that is published on GOV.UK by Mainstream Publisher has a `primary_publishing_organisation` association set on it. This is currently always set to GDS at the point of publishing the content, but we could store this association as part of the content item in Mainstream Publisher, and set it to the relevant organisation. When determining whether a user should have access to a content item, it's Primary Publishing Organisation field would be compared with the user's organisation.

#### Disadvantages

- The Primary Publishing Organisation association already exists for a purpose, and is not intended as a means of access control.
- A content item can only have a single Primary Publishing Organisation, so this solution would not enable content designers from different organisations to be able to see and edit the same content item.
- Due to Primary Publishing Organisation being a one-to-one association with a content item, it doesn't really help us on the journey to supporting multiple-organisation access to a content item.

#### Advantages

- The Primary Publishing Organisation field is an existing field, and so this solution does not require introducing any new fields/concepts (though it is potentially changing the meaning of the association slightly by using it for access control).

### Questions

The Primary Publishing Organisation data flows through the Publishing API and into the content stored in the Content Store. Does it make sense to be changing this data to support access control within Mainstream Publisher (it introduces a level of coupling between two related, but not identical, concepts).

### Option 2: Introducing a new field on content items

A new field could be introduced to content items within Mainstream Publisher to store the organisation(s) whose members should have access to that content item.

#### Disadvantages

- This field will potentially be duplicating the Primary Publishing Organisation association (if there were to become a desire to have that field also reflect this change in which organisation is managing the content item), or tagging information. The Primary Publishing Organisation is not currently exposed to Mainstream Publisher users so this "duplication" won't be apparent to them. See also [this Slack thread](https://gds.slack.com/archives/C051S690LGL/p1720451970243779).
- This solution introduces a new field/concept that is not common to other publishing applications (though Manuals Publisher does to something similar to filter the data that is shown to users).

#### Advantages

- Since this is a new field, it can be made to store a one-to-many association, granting multiple organisations access to a content item.
- This new field will be solely for the purposes of authorisation, it avoids conflating different concerns in a single field/association.
- This field would not be propagated through the Publishing API and would be contained within Mainstream Publisher, eliminating any potential downstream effects.

### Option 3: Use the organisation tagging data to manage permissions

Content Items are "tagged" to organisations (on the "Tagging" tab when viewing an Edition). This tagging is done so that a Content Item will show up when a search is carried out on GOV.UK, filtered to certain organisations.

This option would use that same tagging data to restrict access to a Content Item (i.e. tagging an organisation to a Content Item would grant access to it for users from that organisation).

#### Disadvantages

- Organisation tagging is not intended for limiting access within Mainstream Publisher; using it for such purposes could cause confusion.
- It couples two separate concepts together—just because a Content Item is tagged to an organisation doesn't necessarily mean that content designers from that organisation should be able to see and edit that content.
- Tagging data is not stored within Mainstream Publisher, but by the Publishing API. Tagging data for a content item is fetched when that Content Item is viewed—using it to restrict access from even seeing that content item (e.g. on the Publications page) would involve having to fetch the tagging information for all content items first (which would take far too long), or "back-porting" that data from Publishing API into Mainstream Publisher and then having a mechanism in place to keep that data in sync (which would be a significant piece of work).

#### Advantages

- The tagging data already exists to associate organisations with Content Items.

## Decision

We will implement [option 2](#option-2-introducing-a-new-field-on-content-items). This keeps the field focused on the purpose of authorisation, and also limits the impact to be purely within Mainstream Publisher.

GDS content designers (i.e. those with the "Editor" permission in Signon) will continue to have full access to all Content Items in Mainstream Publisher.

## Consequences

The data for this new field will need to be populated somehow. For existing publications, this will likely be done by creating a rake task to populate the field. The actual data to be used will need to be sourced, for example, by using the existing tagging association to organisations. For newly-created publications, it could either be left unset, or could be set based on the user's organisation. That decision is left outside the scope of this ADR. 
