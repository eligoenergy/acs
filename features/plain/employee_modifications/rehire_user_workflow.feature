Feature: rehire a user
  As a hr member
  I want to rehire a user
  So that they can do their job

  Scenario: hr rehires employee
    Given I am logged in as "nott"
    And I follow "Terminated Users"
    And I follow the link to user "egarret"
    And I press "Rehire Emily Garret"
    Then the user "egarret" should be "active"
    And there should be 2 access request for "egarret"
    And the access request should request to "grant"
    And the access request reason should be "rehire"
    And the access request should be "waiting_for_help_desk_assignment"
    And the access request should be created by "nott"
    And the access request reason should be "rehire"
    And the access request should have 1 permission request
    And I should see "Successfully rehired user and notified help desk"
    And I should be on the user page for "egarret"
    
  Scenario: hr rehires employee with existing termination requests 
    Given I am logged in as "nott"
    And I follow "Terminated Users"
    And I follow the link to user "holajuwon"
    And I press "Rehire Hakeem Olajuwon"
    Then I should be on the user page for "holajuwon"
    And I should see "Termination requests must be completed before the user is rehired"

