# Feature flags

Feature flags in Publisher are managed using the [Flipflop gem](https://github.com/voormedia/flipflop). The gem is
configured with the "cookie" and "default" strategies, plus a lambda strategy that pins a single launched feature on.

## Toggling feature flags

A features dashboard is available to make it easy to toggle features on and off during development.
This dashboard can be accessed at `/flipflop`. Note that this can only be used to toggle feature flags for your user.

## Pinning a feature on

Flipflop resolves a feature by walking the strategies in the order they are listed and taking the first non-nil answer.
A lambda strategy placed above `strategy :cookie` therefore overrides the dashboard for the features it answers for,
and features it returns `nil` for carry on being toggled per user as normal:

```ruby
strategy :my_feature_launched do |feature|
  true if feature == :my_feature
end

strategy :cookie
strategy :default
```

Use this once a feature has launched and you need to stop users switching themselves back onto the old journey, but
still want the old code path and its tests in place for a rollback. Removing the strategy restores per-user control.

Note that [FeatureConstraint](../app/constraints/feature_constraint.rb) reads the cookie directly rather than going
through the strategies, so a pinned feature can still be toggled per user on any route that is constrained on it.

`Flipflop::FeatureSet#test!` replaces the whole strategy chain with the test strategy, so pinning a feature has no
effect on tests, and `switch!` continues to control both paths.

## Testing with feature flags

For testing purposes, feature flags can be configured like so:

```ruby
  setup do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:feature_name, true)
  end
```

## Creating a feature flag

To create a new feature flag, create an entry in the [features.rb](../config/features.rb) file with this format:

```ruby
feature :feature_name,
      default: false,
      description: "A description of the feature"
```

Features should default to `false` while being worked on, meaning users will not see any change without explicitly turning the feature on using the dashboard.

To route the user between different pages based on the status of a feature flag, use the [FeatureConstraint class](../app/constraints/feature_constraint.rb).

For example:

```ruby
app/routes.rb

constraints FeatureConstraint.new("feature_name") do
  get "path/to/page" => "new_controller#action"
end
get "path/to/page" => "old_controller#action"
```

This will route GET requests for `/path/to/page` to `new_controller` when the feature flag is enabled, and to `old_controller` when it is disabled.
