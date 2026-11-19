Feature: The wiki answers and its accounts work
  As the owner of the wiki
  I want the main page, the login and each default account to work
  So that a build that came out broken is caught before anything else is tested

  # Placed by the workspace's testing setup as a starting point: it is yours to change.
  # The accounts are the default ones (cmd-tools-mediawiki-maintenance.sh --add-users); a scenario logs in
  # by a handle of the users registry in cucumber.js, so no password is written here. A test page is made
  # through the wiki's API as the "administrator" account and deleted after the scenario.

  @critical
  Scenario: The main page is served
    Given I am an anonymous user
    When I open the page "Main Page"
    Then I should see the page "Main Page"
    And the scripts of the page should all load

  Scenario Outline: The <account> account logs in
    Given I am an anonymous user
    When I log in as "<account>" with the login form
    Then I should be logged in as "<account>"

    Examples:
      | account       |
      | administrator |
      | editor        |
      | reader        |

  Scenario: A wrong password is refused
    Given I am an anonymous user
    When I log in with the user name "No such account here" and the password "Wrong-password-1"
    Then the login should be refused with "Incorrect username or password entered. Please try again."
    And nobody should be logged in

  Scenario: A page protected for established accounts refuses the new account
    Given the page "Site test page" has the text "A page only established accounts edit."
    And the page "Site test page" is protected so that only autoconfirmed users can edit it
    And I am a logged in user with the "reader" user
    Then editing the page "Site test page" should be refused with "This page has been protected to prevent editing or other actions."

  Scenario: The editor saves a page
    Given the page "Site test page" has the text "A page to change."
    And I am a logged in user with the "editor" user
    When I edit the page "Site test page"
    And I add the wikitext "A line from the editor."
    And I save the page with the summary "A first edit"
    Then the edit should be saved
    And the page text should contain "A line from the editor."
