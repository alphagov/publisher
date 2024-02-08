# Feature flags

Feature flags in Publisher are managed using the [Flipflop gem](https://github.com/voormedia/flipflop). The gem is currently
configured so that only the "cookie" and "default" strategies are active.

## Toggling feature flags

A features dashboard is available to make it easy to toggle features on and off during development.
This dashboard can be accessed at `/flipflop`. Note that this can only be used to toggle feature flags for your user.

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
