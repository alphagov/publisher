Feature: Managing editions
  In order to publish content
  As an editor
  I want to be able to create, assign, review, fact check and publish editions

  Background:
    Given I am signed in to Publisher

  Scenario: Create an edition
    Given I have an artefact in Panopticon
    And I have clicked the create publication button in Panopticon
    When I am redirected to Publisher
    Then a new edition should be created
    And I should see the edit edition form
    And the artefact metadata should be present

  Scenario: View editions
    Given editions exist in Publisher
    When I visit the editions list
    Then I should see each edition in the list

  Scenario: Edit edition
    Given editions exist in Publisher
    When I visit the edit form for an edition
    And I change the title to "Test"
    And I save the changes
    Then the changes should be saved
    And the new edition title should now be "Test"