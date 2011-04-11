Feature: revoke access to a permission
  As a manager
  I want to revoke some access
  So that my subordinate no longer can access a particular permission

  Scenario: manager creates revoke request
    Given I am logged in as "rcooper"
		And "dengle" is my subordinate
		When I go to the revoke access request page
    And I choose "Dan Engle"
    And I press "Next Step"
    And I check permission "jira_admin"
    And I press "Save"
    Then a access request to revoke "admin" access to "jira" should be created
    And the access request should be for "dengle"
    And the access request should be "waiting_for_help_desk_assignment"
    And the access request reason should be "revoke"
		