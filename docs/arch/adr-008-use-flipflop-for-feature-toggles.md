# ADR008 - Use Flipflop for feature toggles

Date 2024-01-12

## Status
Accepted

## Context
As part of the migration of Mainstream Publisher away from Bootstrap and towards the GOV.UK Design System, we wish to be able to have work-in-progress changes viewable in deployed environments (integration/staging/production) without impacting the majority of users. As part of [this spike](https://trello.com/c/uNr9SzAE/599-spike-learn-about-the-flipflop-library) we investigated the use of [Flipflop](https://github.com/voormedia/flipflop), a gem for feature toggles in Rails applications, and which was [recently introduced into Whitehall](https://github.com/alphagov/whitehall/pull/8446).

Flipflop provides a dashboard for viewing the status of toggles at the path `/flipflop`. By default this page is disabled in "production" (which for us would mean all deployed environments), but since we are not planning on putting anything sensitive behind the toggles we have chosen to remove that restriction and make the dashboard always available.

Flipflop provides several different "strategies" for managing toggle status, which summarise to some form of database or cookies. In terms of databases, Active Record, Sequel, and Redis are supported. Since Mainstream Publisher uses MongoDB, which is not supported, we will not be able to store feature toggles in the database (Mainstream Publisher does also connect to a Redis instance, but we have not investigated using that). This leaves us with Cookies as the means to toggle features.

## Decision
We will use Flipflop for feature-toggling within Mainstream Publisher, and the dashboard for toggling features on and off will be available in all environments (users will only be able to toggle features on and off for themselves).

## Consequences
By not restricting access to the toggles dashboard, any user would be able to enable/disable a toggle for themselves. This should not be an issue, since this would just mean a user could potentially view work-in-progress changes for transitioning pages to the design system.

Without storing toggle status in a database, changing a toggle's status will either be per-user, dynamic, (which each user would be able to do dynamically, using the dashboard), or globally, static, by changing the default value in the `config/features.rb` file (which would require a run through of the deployment pipeline whenever this is changed).
