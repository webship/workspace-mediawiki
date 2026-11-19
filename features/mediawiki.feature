Feature: The MediaWiki plugin on the dashboard
  Once the plugin is activated and installed, the sites folders offer the MediaWiki builder, each
  AI folder lists the items of its kind the plugin ships, and the Plugins page lists the plugin
  with its steps.

  # Settings lists every plugin that was added; the package and what the plugin ships are on its own page.
  Scenario: Settings lists the plugin, and its own page names its package and what it ships
    Given I am on "/settings"
     Then I should see "MediaWiki"
     When I go to "/settings/plugin/mediawiki"
     Then I should see "@webship.co/workspace-mediawiki"
      And I should see "cmd-mediawiki-project.sh"
      And I should see "mediawiki-site-builder"

  Scenario: A sites folder offers the MediaWiki builder
    Given I am on "/dev"
     Then "option[value='cmd-mediawiki-project.sh']" should be attached

  # The AI folders are searched by name: with every plugin on, a folder lists more than one page of items.
  Scenario: The AI Agents folder lists the agents the plugin ships
    Given I am on "/ai-agents?q=mediawiki-"
     Then I should see "mediawiki-site-builder"
      And I should see "mediawiki-tester"

  Scenario: The AI Skills folder lists the skill the plugin ships
    Given I am on "/ai-skills?q=mediawiki-scenarios"
     Then I should see "mediawiki-scenarios"

  Scenario: The AI Commands folder lists the command the plugin ships
    Given I am on "/ai-commands?q=mediawiki-test"
     Then I should see "mediawiki-test"

  Scenario: The AI Prompts folder lists the prompts the plugin ships
    Given I am on "/ai-prompts?q=mediawiki-"
     Then I should see "mediawiki-build-and-test"
      And I should see "mediawiki-scenarios-for-an-area"
