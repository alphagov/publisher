# ADR014 Replacement of Email-based Fact Checking Process in Publisher

## Date 2025-10-23

## Status
Accepted

## Context

Publisher’s existing email-based fact check workflow depends on a deprecated email service. Its unreliability has led to repeated operational issues (e.g. email processing failures) and created significant manual toil for the Mainstream team.

Factors leading to this decision were captured in this [RFC](https://github.com/alphagov/govuk-rfcs/pull/186)

---

## Decision

We will **replace the current email-based fact check workflow** with a **Rails Engine embedded within the Mainstream Publisher application**.

This engine will:
- Allow SMEs to review and respond to fact checks directly within a secure web interface (no email).
- Provide structured, auditable feedback and track reviewer actions.
- Support multiple reviewers.
- Integrate authentication via Signon or magic-link based access.
- Reuse Publisher’s existing codebase and logic to minimize development effort.
- Allow future extraction into a standalone service if cross-app adoption becomes desirable.

---
## Considerations
 The disadvantages of implementing Rails Engine are the need for careful management of boundaries between the engine and the rest of the application, as well as the initial setup effort and some ongoing maintenance overhead.

---
## Consequences

Three main implementation options were considered:

1. **Direct integration into Publisher** – tightly coupled, increases complexity and security exposure.  
2. **Standalone Fact Check application** – clean separation but high cost, integration overhead, and limited reuse value.  
3. **Rails Engine within Publisher** – optimal trade-off between delivery speed, maintainability, and future flexibility.

Option 3 was selected because it:
- Minimizes disruption to existing systems.
- Keeps scope manageable within current delivery timelines.
- Enables long-term adaptability (extractable engine design).
- Balances operational simplicity with architectural soundness.
