# FV2AuthPlugin

Here is an Authorization Plugin that is designed to automatically, seamlessly and silently add users to FileVault 2 while the user is authenticating at the Login Window.

## system.login.console

The Authorization Plugin is called from the system.login.console in the authorization databse.

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

Authorization Plugins give us access to a gold mine of information during the login process. We are able to capture the login user's username and clear text password. The FV2AuthPlugin runs after the builtin:authenticate,privileged runs, so we know that password used is valid.

Now that we have the user's credenials, all we need is an admin account to authorize FV2 addition. Since we run the FV2AuthPlugin in privileged mode we have the ability to create a temporary local admin user and set it's password.

The /usr/lib/libodfde.dylib has an undocumented symbol ` ODFDEAddUser `. Thanks to @russellhancox for publishing the correct variables needed in the macdestoryer repo:

https://github.com/google/macops/tree/master/macdestroyer

```objective0c
extern BOOL ODFDEAddUser(CFStringRef authuser, CFStringRef authpass, CFStringRef username, CFStringRef password);
```

We now have everything we need to add a user to FileVault2. Keep in mind that ODFDEAddUser is undocumented and will most likely be changed in future release of OS X.

This symbol still exists in 10.10.2 and works for our purposes.

