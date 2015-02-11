# FV2AuthPlugin

Here is an Authorization Plugin that is designed to automatically, seemlessly and silently add users to FileVault 2 while autenticating at the Login Window.

The Authorization Plugin is called from the system.login.console in the authorization databse.
## system.login.console

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>class</key>
	<string>evaluate-mechanisms</string>
	<key>comment</key>
	<string>Login mechanism based rule.  Not for general use, yet.</string>
	<key>created</key>
	<real>440105275.951406</real>
	<key>mechanisms</key>
	<array>
		<string>builtin:policy-banner</string>
		<string>loginwindow:login</string>
		<string>builtin:login-begin</string>
		<string>builtin:reset-password,privileged</string>
		<string>builtin:forward-login,privileged</string>
		<string>builtin:auto-login,privileged</string>
		<string>builtin:authenticate,privileged</string>
		<string>PKINITMechanism:auth,privileged</string>
		<string>FV2AuthPlugin:add-users,privileged</string>
		<string>builtin:login-success</string>
		<string>loginwindow:success</string>
		<string>HomeDirMechanism:login,privileged</string>
		<string>HomeDirMechanism:status</string>
		<string>MCXMechanism:login</string>
		<string>loginwindow:done</string>
	</array>
	<key>modified</key>
	<real>445305832.28244603</real>
	<key>shared</key>
	<true/>
	<key>tries</key>
	<integer>10000</integer>
	<key>version</key>
	<integer>1</integer>
</dict>
</plist>
```
## How does it work?



