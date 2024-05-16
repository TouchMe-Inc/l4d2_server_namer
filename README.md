# About server_namer
Changes the server hostname to match the current game mode.

## Example 1:
server.cfg:
```
sn_custom_hostname "My local server #1"
sn_custom_gamemode "Versus | T1"
sn_hostname_template "{hostname} | {gamemode}"
sn_hostname_template_free "*FREE* {hostname} | {gamemode}"
```

Result:
```
My local server #1 | Versus | T1
```
OR (no players)
```
*FREE* My local server #1 | Versus | T1
```

## Example 2:
server.cfg:
```
sn_custom_hostname "My local server #2"
sn_custom_gamemode ""
sn_hostname_template "{hostname} | {gamemode}"
sn_hostname_template_free "*FREE* {hostname} | {gamemode}"
```

Result:
```
My local server #2 | Versus
```
OR (no players)
```
*FREE* My local server #2 | Versus
```
