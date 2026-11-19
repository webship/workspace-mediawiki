Feature: Editing a page
  The editor changes a page in the source editor and in the visual editor, and the history shows
  each change by its summary. The visual editor needs a wiki built with --visual-editor.

  Scenario: The source editor, with the changes checked before the save
    Given the page "Skill editing page" has the text "Words to change." with the summary "First version"
    And I am a logged in user with the "editor" user
    When I edit the page "Skill editing page"
    And I set the wikitext to "Words changed in the source editor."
    And I show my changes
    Then the changes should show "Words changed in the source editor." added
    When I save the page with the summary "A clearer sentence"
    Then the edit should be saved
    When I open the history of the page "Skill editing page"
    Then the history should list the revision "A clearer sentence" by "editor"
    And the history should list the revision "First version" by "administrator"

  Scenario: The visual editor
    Given the page "Skill visual page" has the text "A page to change."
    And I am a logged in user with the "editor" user
    When I edit the page "Skill visual page" in the visual editor
    And I type " Typed in the visual editor." in the visual editor
    And I save the page with the summary "A sentence in the visual editor"
    Then the visual editor should not be open
    And the page text should contain "Typed in the visual editor."
