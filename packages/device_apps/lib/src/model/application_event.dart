enum ApplicationEventType {
  // Application is installed
  installed,

  // Application is updated (eg: from version 1 to 2)
  updated,
  // Application is uninstalled from the device
  uninstalled,

  // Application is enabled by the user
  enabled,

  // Application is disabled by the user (but still installed)
  disabled,
}
