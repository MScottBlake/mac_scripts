# setWirelessPreferences.sh

This script sets wireless preferences according to input parameters. Boolean settings may be configured using 'YES' and 'NO'. Leave a parameter blank to ignore it.

## Available preferences from Airport command
- DisconnectOnLogout (Boolean)
- JoinMode (String)
  - Automatic
  - Preferred
  - Ranked
  - Recent
  - Strongest
- JoinModeFallback (String)
  - Prompt
  - JoinOpen
  - KeepLooking
  - DoNothing
- RememberRecentNetworks (Boolean)
- RequireAdmin (Boolean)
- RequireAdminIBSS (Boolean)
- RequireAdminNetworkChange (Boolean)
- RequireAdminPowerToggle (Boolean)
- WoWEnabled (Boolean)

## Default Parameter Mapping
| Arg | Parameter Label           | Valid Values                                    |
|-----|---------------------------|-------------------------------------------------|
|  $4 | DisconnectOnLogout        | YES, NO                                         |
|  $5 | JoinMode                  | Automatic, Preferred, Ranked, Recent, Strongest |
|  $6 | JoinModeFallback          | Prompt, JoinOpen, KeepLooking, DoNothing        |
|  $7 | RememberRecentNetworks    | YES, NO                                         |
|  $8 | RequireAdmin              | YES, NO                                         |
|  $9 | RequireAdminIBSS          | YES, NO                                         |
| $10 | RequireAdminNetworkChange | YES, NO                                         |
| $11 | RequireAdminPowerToggle   | YES, NO                                         |
| ~~$12~~ | ~~WoWEnabled~~        | ~~YES, NO~~                                     |
