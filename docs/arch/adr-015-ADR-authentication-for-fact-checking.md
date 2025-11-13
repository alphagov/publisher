# ADR015 Authentication Approach for the Fact Check Tool

## Date 2025-11-13

## Status
Accepted

## Context

The Fact Check tool in Publisher replaces email-based workflows with a secure, auditable interface.

- MVP 1: Only departmental SPOCs will access the tool to submit final responses after collecting SME feedback offline.
- MVP 2: SMEs will gain limited direct access to comment.

## Decision

- MVP 1: Use GOV.UK Signon exclusively for all users (SPOCs).
- MVP 2: Introduce Magic Link for occasional users (SMEs) alongside Signon for SPOCs and other regular users.

By the Magic Link here we undestand a lightweight authentication where users confirm their identity by proving access to their email address: they click a link, verify their email, receive a short-lived code or second link, and use it to access the Fact Check page.
- Shared inboxes: Only individuals with Signon accounts may access the tool after receiving email notification.

## Considerations

- Magic Link requires additional development effort and has been deferred to MVP 2.
- Shared inboxes cannot authenticate; individual access preserves accountability.
- Roles (spoc, sme, admin) will be introduced for users.

## Consequences

- Positive: Secure access from MVP 1; minimal setup using existing Signon.
- Trade-offs: SPOCs may need manual account activation; SMEs cannot yet log in.
- Future: Hybrid Signon + Magic Link in MVP 2.
