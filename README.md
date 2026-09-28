# MySQL Workbench Temporary Session Launcher

An AutoIt automation script that starts MySQL Workbench, creates a saved database connection from supplied values, opens it, then returns the session to the active SQL connection. It is intended for controlled Windows desktop, Microsoft RemoteApp/RDS, and PAM-launched workflows.

> **Important:** The supplied script is published exactly as provided. Its UI coordinates, delays, argument mapping, and workflow have not been changed.

## Prerequisites

- Windows with [AutoIt v3](https://www.autoitscript.com/site/autoit/) installed, or a compiled copy of the script.
- MySQL Workbench installed at `C:\Program Files\MySQL\MySQL Workbench\MySQL Workbench.exe`.
- A desktop or RemoteApp session with an interactive MySQL Workbench window. The automation uses fixed screen coordinates and was observed with MySQL Workbench 26.7.0.0.
- Network access and an authorized MySQL account for the target database.

## Parameters

The implementation reads three positional parameters:

| Position | Value | Used for |
| --- | --- | --- |
| 1 | Host | Connection name and MySQL host/IP address |
| 2 | User | MySQL user name |
| 3 | Password | Password entered in the Workbench credential dialog |

Although the header comments mention `[Caption] [Host] [User] [Password]`, the script as supplied reads **Host, User, Password** only. Do not add a separate caption argument unless you also intentionally change the script.

## Run from Command Prompt

Open Command Prompt in the repository folder and run:

```cmd
"C:\Program Files (x86)\AutoIt3\AutoIt3.exe" "MySQL-Workbench-TempSessionLauncher.au3" "10.10.10.25" "dbuser" "SecretPassword"
```

If you compile the script to an executable, use the same order:

```cmd
"C:\Path\To\MySQL-Workbench-TempSessionLauncher.exe" "10.10.10.25" "dbuser" "SecretPassword"
```

## Microsoft RemoteApp / RDS

1. Install AutoIt and MySQL Workbench on the RDS host, or deploy a compiled script alongside MySQL Workbench.
2. Confirm that the MySQL Workbench path in the script exists on that host.
3. Publish the launcher as a RemoteApp, or configure the RemoteApp command line to supply the three values in this order: `Host User Password`.
4. Test in the exact RemoteApp window size, display scaling, and Workbench version that users will run. Fixed coordinates can change with DPI scaling, UI layout, or version changes.
5. Ensure the session is interactive and not minimized when the launcher runs.

Example RemoteApp command line:

```text
"C:\Path\To\MySQL-Workbench-TempSessionLauncher.exe" "10.10.10.25" "dbuser" "SecretPassword"
```

## PAM + RemoteApp sessions

Use your PAM product to broker the RemoteApp session and inject the connection values into the approved launcher command line.

1. Create an approved application entry that launches the compiled AutoIt executable (or AutoIt with the `.au3` file).
2. Map the PAM-managed target host, database username, and retrieved password to arguments 1, 2, and 3 respectively.
3. Start the launcher only after the RemoteApp session is fully interactive.
4. Limit access to the published application and audit session launches according to your PAM policy.
5. Validate in a non-production account before granting production access.

The integration must not pass a fourth caption argument to this unmodified script, because that shifts every subsequent value and causes incorrect host, user, and password mapping.

## Operational notes

- The script relies on fixed mouse coordinates and observed MySQL Workbench UI behavior; it may need revalidation after changing screen resolution, scaling, Workbench version, theme, or window layout.
- It uses a 10-second Workbench startup wait and an 8-second render delay.
- The saved connection is opened and subsequently deleted by the supplied workflow. Review this behavior carefully before deploying it for shared or persistent Workbench profiles.
- Run only in an interactive user session where MySQL Workbench can receive focus.

## Security warning

Passing passwords on a command line is risky. Command-line arguments can be exposed to local processes, monitoring tools, shell history, RemoteApp/PAM logging, crash reports, and diagnostic captures. Avoid placing real passwords in batch files, shortcuts, source control, or operational documentation.

For production, prefer a PAM-supported secret injection mechanism that does not expose the password in the process command line, and consider a secure retrieval method such as DPAPI when an architectural change is permitted. Apply least privilege, restrict access to the launcher, and test your PAM logging/redaction settings before deployment.

## License

No license has been specified. Contact the repository owner before reuse beyond your organization’s approved use.
