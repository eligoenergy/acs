Feature: help desk processes access request
	As a help desk member
	I want to process an access requests that is waiting for help desk
	So that their access is modified

	Scenario: process request access
    Given I am logged in as "mstreet"
		And I have the role "help_desk"
		And "dengle_wiki_help_desk" is an access request created by "dengle"
		And the access request should be "waiting_for_help_desk_assignment"
        And I follow the link for "dengle_wiki_help_desk"
		And I press "Assign to me"
		And I press "Mark as complete"
		Then I should be on the show access request page for "dengle_wiki_help_desk"
		And I should see "Access request completed"
		And the access request should be "completed"
    And the access request should be unassigned
		And "dengle" should have "wiki_admin" permissions
		
	Scenario: help desk processes revoke request
	  Given I am logged in as "mstreet"
		And I have the role "help_desk"
		And "dengle" has "acunote_admin" permission
		When I go to the dashboard page
        And I follow the link for "dengle_revoke_acunote_help_desk"
		And I press "Assign to me"
		And I press "Mark as complete"
		Then I should be on the show access request page for "dengle_revoke_acunote_help_desk"
		And I should see "Marvin Street processed"
		And "dengle" should not have "acunote_admin" permission
    
  Scenario: help desk unassign a request in progress
    Given I am logged in as "jserrano"
    And I have the role "help_desk"
    And "rcooper_wiki_help_desk" is an access request created by "rcooper"
    When I go to the dashboard page
    And I follow "Requests at Help Desk"
    And I follow the link for "rcooper_wiki_help_desk"
    And I press "Unassign Access Request"
    Then the access request should be "waiting_for_help_desk_assignment"
    And the access request should be unassigned
    And I should see "Access Request has been unassigned"
    And I should be on the show access request page for "rcooper_wiki_help_desk"
    