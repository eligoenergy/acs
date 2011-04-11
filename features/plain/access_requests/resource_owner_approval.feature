Feature: resource owner processes access request
	As a resource owner
	I want to process an access requests for a resource I own
	So that their access is modified

	Scenario: approve request access for resource you own
    Given I am logged in as "timothyho"
		And I am an owner of "uk_portal"
		And "dengle_uk_portal_resource_owner" is an access request created by "dengle"
		And it is waiting for resource owner assignment
    And I follow the link for "dengle_uk_portal_resource_owner"
		And I press "Assign to me"
		And I "approve" "access_request_resource_owner_approval_attributes" for "admin"
    And I fill in "access_request_notes_attributes__body" with "approved"
		And I press "Process Request"

		Then I should be on the show access request page for "dengle_uk_portal_resource_owner"
		And I should see "Request has been sent to help desk"
		And the access request should be "waiting_for_help_desk_assignment"

	Scenario: deny request access for resource you own
	  Given I am logged in as "timothyho"
		And I am an owner of "uk_portal"
		And "dengle_uk_portal_resource_owner" is an access request created by "dengle"
		And it is waiting for resource owner assignment
    And I follow the link for "dengle_uk_portal_resource_owner"
		And I press "Assign to me"
		And I "deny" "access_request_resource_owner_approval_attributes" for "admin"
    And I fill in "access_request_notes_attributes__body" with "denied"
		And I press "Process Request"
		Then I should be on the show access request page for "dengle_uk_portal_resource_owner"
		And I should see "Denying request"
		And the access request should be "denied"

	Scenario: forget to approve/deny
  	Given I am logged in as "timothyho"
		And I am an owner of "uk_portal"
		And "dengle_uk_portal_resource_owner" is an access request created by "dengle"
		And it is waiting for resource owner assignment
    And I follow the link for "dengle_uk_portal_resource_owner"
		And I press "Assign to me"
		And I press "Process Request"
		Then I should be on the resource owner approval page for "dengle_uk_portal_resource_owner"
		And I should see "Please approve or deny admin access"
		And the access request should be "waiting_for_resource_owner"

    Scenario: Owner's Manager approves request
    Given I am logged in as "timothyho"
        And "mgroulx" is my subordinate
        And "acunote" is owned by "mgroulx"
        And "rcooper_acunote_admin" is an access request created by "rcooper"
        And it is waiting for resource owner assignment
    And I follow the link for "rcooper_acunote_admin"
        And I press "Assign to me"
        And I "approve" "access_request_resource_owner_approval_attributes" for "admin"
    And I fill in "access_request_notes_attributes__body" with "approved"
        And I press "Process Request"
        Then I should be on the show access request page for "rcooper_acunote_admin"
        And I should see "Request has been sent to help desk"
        And the access request should be "waiting_for_help_desk_assignment"

