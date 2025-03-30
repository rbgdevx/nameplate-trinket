# Nameplate Trinket

## [v2.1.15](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.15) (2025-03-30)

- Adding support for Tidyplates nameplates

## [v2.1.14](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.14) (2025-03-14)

- Fixing support for Plater
- Update toc

## [v2.1.13](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.13) (2025-02-22)

- Adding the ability to test on NPC nameplates
- Updating settings visuals and placements
- Adding support for Plater, KUI, and ElvUI
- Removing combat log healer check

## [v2.1.12](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.12) (2025-01-28)

- Fixing visibility when in instances if test mode is still enabled

## [v2.1.11](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.11) (2025-01-14)

- Fixing visibility control for which zones you want this to show in
- Reducing zone control down to pvp and world pvp since nameplate ui changes basically don't work in PVE nor would you need this addon for pve
- Fixing the healer reduction on pvp trinkets due to key type into the spells db
- Converting all spell keys to be number based since in all api responses the spell ids are numbers
- Added a db migration tool to migrate old spell string keys to number keys
- Added type checking to ensure i was covering areas correctly
- backend updates from type checking
- Added option to control enemy visibility so now you can control friendly and enemies, not just friendly

## [v2.1.10](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.10) (2024-12-20)

- Fixing nameplate strata and level
- Drag and Click control updates to ensure click through when hidden or locked
- Fixing font dropdown list
- Updating font size range
- Minor Cleanup
- Update toc

## [v2.1.9](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.9) (2024-12-12)

- Ensuring when you change the offsets that it applies everywhere immediately and stays even if you don't reload

## [v2.1.8](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.8) (2024-12-10)

- Refactoring nameplate anchoring to be consistent and up to date with blizzards apis
- updating default settings

## [v2.1.7](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.7) (2024-12-03)

- Minor cleanup
- Changing conditional logic on healer check function so it can pass through
- Adding additional healthbar anchor option
- Fixing test mode show/hide logic
- Adding fallback attachment frame

## [v2.1.6](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.6) (2024-12-02)

- Adding back old healer check code and updating to be more performant
- Adding a few more checks to exclude npcs
- Updating nameplate anchors
- Opting out of combat log events for npcs while accommodating for mind controlled players still

## [v2.1.5](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.5) (2024-11-27)

- Removing call to function that doesn't exist

## [v2.1.4](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.4) (2024-11-27)

- Fixing some database initialization bugs

## [v2.1.3](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.3) (2024-11-27)

- Added all new Spells tab! This allows you to see and control all the spells being tracked
  - You can add a new spell by Spell ID or Spell Name and it will ensure if its valid or not for you
  - Provides settings you can override for each spell including
    - The ability to enable or disable the spell
    - Spell ID
    - Cooldown
    - Spell Icon ID
    - And the ability to remove the spell
- Adding a sort dropdown so you can control the sorting of the icons displayed
- Updating default config settings
- Removing old unused code
- Updating variable names
- Updating database initialization utility functions

## [v2.1.2](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.2) (2024-11-21)

- fixing incorrect logic when checking for valid instance types
- adding check for early return in combat log if not tracking self in settings

## [v2.1.1](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.1.1) (2024-11-21)

- MASSIVE performance enhancements, like an insane difference based on latest research and testing
  - biggest thing is leveraging nameplate as frame directly instead of nameplate.UnitFrame
- reduction in code util functions
- reduced extra healer check code as its not needed for this addon
- added a check to stop combat log code if outside of an instance and test mode is active
- disable test mode when entering into an instance
- creating a frame name to latch onto for OmniCC settings
- variable name updates
- adding fallback nameplate anchor
- simplify refreshNameplates function
- minor cleanup
- while tracking trinket only we return early in combat log if not a trinket

## [v2.0.1](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.0.1) (2024-11-19)

- Fixing event registration usage
- Fixing clearing of spells and nameplates
- Better matching spell removal and placement to its original code in NameplateCooldowns to fix some bugs
- Ensuring some enter world code only runs once to better match its original code in NameplateCooldowns
- Fixing placement of healer in group code on group roster update
- Updated print message for nil or unknown instance types
- Removed Zone area check

## [v2.0.0](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v2.0.0) (2024-11-19)

- Complete refactor from the ground up
  - overhaul of nameplate add/remove code to instead follow more closely to BetterBlizzPlates then NameplateCooldowns
  - overhaul of nameplate hide/show code to instead follow more closely to BetterBlizzPlates then NameplateCooldowns
  - overhaul of the combat log to include pre-filtering checks to reduce code running frequency and amount
  - creating a shared namespace for myself on nameplate frames as i intend to make more nameplate addons which i can reduce frame additions
  - overhaul of the event setting and de-setting to instead just let the code run anytime and we'll determine when to show instead via settings but leave it available if toggled on
  - overhaul of the testing setup to better match NameplateCooldowns
  - overhaul showing/hiding non-trinket spells when toggling off the trinket only setting
  - overhaul showing/hiding/placing spells when they go on cooldown or come off of cooldown to better match NameplateCooldowns
  - overhaul combat log spell capturing to simplify conditions and logic
- all new ways to check for healers including a simpler refactor and integration of the old lib
- fixing nameplate and icon refresh code and scenarios to better match NameplateCooldowns
- added checks throughout the codebase to have more early returns to process less code if conditions aren't met
- allowing glow to show up on any trinket based spell
- adjusting spell filtering which fixed a show/hide bug off cooldown
- removed no longer needed code due to overhaul
- all new settings to hide icons in any instance type
- removed a ton of legacy settings code
- lots of cleanup

## [v1.0.4](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v1.0.4) (2024-10-27)

- Resets spells between solo shuffle rounds
- Reduces space between icons and size of icons by 1

## [v1.0.3](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v1.0.3) (2024-10-27)

- Fixes namespace of custom frames to be unique to this addon and not conflict with the addon i based this off of
- Handles resetting nameplate custom frames when starting and stopping test mode
- Adds new option to set frame strata and icon alpha as requested via feedback
- Adds glow effect back in for trinkets and an option to disable it
- Adds another chance to hide non-player frames if they bounce and get reused as nameplates
- Removes a ton of old helper utilities no longer used
- update toc

## [v1.0.2](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v1.0.2) (2024-10-21)

- Updating anchor setting function
- Fixing incorrect unregistering of events in relation to test mode
- Updating test mode code
- Adding addition code to hide non-player frames if they exist or come up
- Adjusting wiping test code for outdoor combat and when you leave outdoor combat
- Removing some old cleanup code in favor of new code

## [v1.0.1](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v1.0.1) (2024-10-17)

- adding wow interface id
- fixing slash commands to correct acronym

## [v1.0.0](https://github.com/rbgdevx/nameplate-trinket/releases/tag/v1.0.0) (2024-10-17)

- initial release
