Feature: manager processes access request
	As an manager
	I want to process my subordinates access requests
	So that their access is controlled

	Scenario: approve request access for subordinate
    Given I am logged in as "rcooper"
		And "dengle" is my subordinate
		And "dengle_cnu_portal" is an access request created by "dengle"
		And I am on the dashboard page
    And I follow the link for "dengle_cnu_portal"
		Then I should be on the show access request page for "dengle_cnu_portal"
		And I should see "Current Status: Waiting for manager"
		And I "approve" "access_request_manager_approval_attributes" for "admin"
    And I fill in "access_request_notes_attributes__body" with "approved"
		And I press "Process Request"
		Then I should be on the show access request page for "dengle_cnu_portal"
		And I should see "Notifying resource owners"

	Scenario: approve request access for subordinate
    Given I am logged in as "mstreet"
		And "jserrano" is my subordinate
		And "jserrano_wiki_waiting_for_manager" is an access request created by "jserrano"
		And I am on the dashboard page
    And I follow the link for "jserrano_wiki_waiting_for_manager"
		Then I should be on the show access request page for "jserrano_wiki_waiting_for_manager"
		And I should see "Current Status: Waiting for manager"
		And I "approve" "access_request_manager_approval_attributes" for "wiki"
    And I fill in "access_request_notes_attributes__body" with "approved"
		And I press "Process Request"
		Then I should be on the show access request page for "jserrano_wiki_waiting_for_manager"
		And I should see "Request has been assigned to Marc Groulx for resource owner approval."
    And the access request should be "waiting_for_resource_owner"
    And the access request resource owner should be "mgroulx"
    And the access request should be assigned to "mgroulx"
    
	Scenario: deny request access for subordinate
	  Given I am logged in as "rcooper"
		And "dengle" is my subordinate
		And "dengle_cnu_portal" is an access request created by "dengle"
		And I am on the dashboard page
        And I follow the link for "dengle_cnu_portal"
		Then I should be on the show access request page for "dengle_cnu_portal"
		And I should see "Current Status: Waiting for manager"
		And I should see "Dan Engle requested"
		And I should see "admin"
		And I "deny" "access_request_manager_approval_attributes" for "admin"
    And I fill in "access_request_notes_attributes__body" with "denied"
		And I press "Process Request"
		Then I should be on the show access request page for "dengle_cnu_portal"
		And I should see "Denying request"
		And the access request should be "denied"

	Scenario: process request access for subordinate but forget to approve/deny
	  Given I am logged in as "rcooper"
		And I am on the dashboard page
		And "dengle" is my subordinate
		And "dengle_cnu_portal" is an access request created by "dengle"
		And I follow the link for "dengle_cnu_portal"
        Then I should be on the show access request page for "dengle_cnu_portal"
		And I should see "Current Status: Waiting for manager"
		And I should see "Dan Engle requested"
		And I should see "admin"
		And I press "Process Request"
		Then I should be on the manager approval page for "dengle_cnu_portal"
		And I should see "Please approve or deny admin access"
    And I should see "Notes body can't be blank"

	Scenario: process request access for subordinate and add note but forget to approve/deny
	  Given I am logged in as "rcooper"
		And I am on the dashboard page
		And "dengle" is my subordinate
		And "dengle_cnu_portal" is an access request created by "dengle"
		And I follow the link for "dengle_cnu_portal"
        Then I should be on the show access request page for "dengle_cnu_portal"
		And I should see "Current Status: Waiting for manager"
		And I should see "Dan Engle requested"
		And I should see "admin"
    And I fill in "access_request_notes_attributes__body" with "approved"
		And I press "Process Request"
		Then I should be on the manager approval page for "dengle_cnu_portal"
		And I should see "Please approve or deny admin access"

    Scenario: Manager's Manager approves a request
      Given I am logged in as "timothyho"
        And I am on the dashboard page
        And "rcooper" is my subordinate
        And "dengle" is subordinate to "rcooper"
        And "dengle_cnu_portal" is an access request created by "dengle"
        And I follow the link for "dengle_cnu_portal"
      Then I should be on the show access request page for "dengle_cnu_portal"
		And I should see "Current Status: Waiting for manager"
		And I should see "Cash Net Usa (Portal Access)"
        And I "approve" "access_request_manager_approval_attributes" for "admin"
        And I fill in "access_request_notes_attributes__body" with "approved by manager's manager"
		And I press "Process Request"
      Then I should be on the show access request page for "dengle_cnu_portal"
		And I should see "Notifying resource owners"

  Scenario: view an access request that was denied by your manager
    Given I am logged in as "alee"
    And "alee_cyberark_admin" is an access request created by "alee"
    When I follow the link for "alee_cyberark_admin"
    Then I should see "Olga Dolchenko denied"
    And I should not see "Resource Owner Approval"
    And I should see "This access request has been denied"
    And I should see "Comments are disabled for access requests that were completed more than 15 minutes ago"

