Feature: The administrator protects and deletes pages
  A page protected for established accounts refuses a new account; a deleted page can be restored.

  Scenario: The new account is refused a protected page
    Given the page "Skill protected page" has the text "Only established accounts edit this page."
    And the page "Skill protected page" is protected so that only autoconfirmed users can edit it
    And I am a logged in user with the "reader" user
    Then editing the page "Skill protected page" should be refused with "This page has been protected to prevent editing or other actions."

  Scenario: A page deleted and restored
    Given the page "Skill deleted page" has the text "A page to delete and restore."
    And I am a logged in user with the "administrator" user
    When I delete the page "Skill deleted page" with the reason "A test of the deletion"
    Then the page "Skill deleted page" should not exist
    When I restore the page "Skill deleted page" with the reason "A test of the restore"
    Then the page "Skill deleted page" should exist
