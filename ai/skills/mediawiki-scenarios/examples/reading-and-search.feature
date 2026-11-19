Feature: Reading and searching the wiki
  A reader opens a page with its sections and links, and finds a page by the search box and by
  a full search. The scenarios make their own pages, which are deleted after each one.

  Background:
    Given the page "Skill second page" has the text "The page the reading page links to."
    And the page "Skill reading page" has the text:
      """
      Lighthouses guide ships along the coast.

      == Overview ==
      A page of the wiki: [[Skill second page]].

      == History ==
      A page that does not exist yet: [[Skill page not written]].
      """

  Scenario: A visitor reads the page and follows a link
    Given I am an anonymous user
    When I open the page "Skill reading page"
    Then I should see the page "Skill reading page"
    And the page should have the section "Overview"
    And the page should link to the page "Skill second page"
    And the page should link to the missing page "Skill page not written"
    When I follow the link to the page "Skill second page"
    Then I should see the page "Skill second page"

  Scenario: The search box suggests the page
    Given I am an anonymous user
    And I am on the page "Main Page"
    When I type "Skill readi" in the search box
    Then the search suggestions should list "Skill reading page"
    When I choose the suggestion "Skill reading page"
    Then I should see the page "Skill reading page"

  Scenario: A full search finds the page by a word of its text
    Given I am an anonymous user
    And I am on the page "Main Page"
    When I search for "lighthouses"
    Then the search results should list the page "Skill reading page"
    And the search result "Skill reading page" should mention "lighthouses"
