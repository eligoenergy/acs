Feature: employee requests additional access request
  As an employee
  I want to request access
  So that I or my subordinate can access a resource

  Scenario: request access
    Given I am logged in as "dengle"
    And I do not have any access to the resource "Cyberark" from resource group "application_access"
    When I go to the new access request page
    And I check "Cyberark"
    And press "Next Step"
		And I check "admin"
    And I fill in "access_request_0_notes_attributes_body" with "yes please"
    And I press "Save"
    Then an Access Request should be created for me
    And the access request should be "waiting_for_manager"
    And the access request reason should be "standard"
    And it should have a permission request for "admin" access
    And it should be for "Cyberark"
    And it should be assigned to my manager
		And I should see "Access request has been sent to your manager."

  Scenario: request access to a resource that you already have a pending access request for
    Given I am logged in as "dengle"
    And I have a pending access request for "Cash Net Usa" from resource group "portal_access"
    When I go to the new access request page
    And I check "Cash Net Usa"
    And I press "Next Step"
    Then the checkbox for "cnu_portal_admin" should be disabled
    And the checkbox for "cnu_portal_executive" should be disabled

  Scenario: request access for a subordinate
    Given I am logged in as "rcooper"
    And "dengle" is my subordinate
    When I go to the new access request page
    And I select "dengle" from "access_request_user_id"
    And I check "Cyberark"
    And I press "Next Step"
    And I check "admin"
    And I fill in "access_request_0_notes_attributes_body" with "its useful"
    And I press "Save"
    Then an Access Request should be created for "dengle"
    And the access request should be "waiting_for_resource_owner_assignment"
    And the access request reason should be "standard"
    And it should have a permission request for "admin" access
    And it should be for "Cyberark"
    And the access request should be "waiting_for_resource_owner_assignment"
    And I should see "Resource owners have been notified about your access request"

