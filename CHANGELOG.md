# 3.1.2

- Update winsw download url to winsw org

# 3.1.1

- Update default winsw version to winsw-v2.6.2

# 3.1.0

- Evaluate service status guard conditions lazily
- Re-install service if `startmode` is changed

# 3.0.0

- Update to to Chef 15.x

# 2.0.3

- Re-order default supported_runtimes from highest to lowest versions

# 2.0.2

- Ensure WinSW configuration validation does not interfere with running service

# 2.0.1

- Check for existence of service descriptor xml before restarting
- Remove executable wrapper bat

# 2.0.0

- Validate WinSW configuration on install/start/restart
- Ability to configure extensions and more complex logging modes
- Default to WinSW 2.x binary

# 0.1.0

- Initial release of WinSW cookbook
