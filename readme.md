Overview
--------

Identifies and uninstalls Oracle's Java software from the local machine using WMI. The query to locate the installed software interogates the WIN32_Products class and includes exclusions to avoid matches to third party software that has "Java" in it's name.
Use the -KeepVersion argument to specifiy a version to keep installed on a computer.
Use the -Whatif switch to test the result without actually uninstalling anything.

See the documentation page for a full list of options and their descriptions 

The script will return the results of the WMI query as an object array.
Credit to commenter on my blog "Carsten" who supplied an expanded list of software to exclude.
Note: this script is supplied "as is" and has not been fully tested for all possible scenarios. Use at your own risk and do full testing before using in production.

Usage
-----

There are two different methods of using the Powershell code provided. There is a PS1 script file which can be used without any "installation" through whichever deployment\execution method is suitable. E.g SCCM.
The PSM1 module must be deployed into the Powershell Modules folder and will then be available as a cmdlet that can be used in a larger Powershell script or interactively.

There are a number of options available to control how the script/module will work.

-Whatif Will report back the Java programs found that it would uninstall if the Whatif switch wasn't used. It returns the results as a set of objects that were retrieved from WMI so that they can be consumed by other Powershell cmdlets (e.g. export to a file for reporting)

-Keepversion Requires a full or partial Java version number (e.g. 7.0.51 or 7) which specifies a Major version or Update to remain installed whilist removing all other versions.

-Wait Waits for any processes with a process name beginning with "Java" to terminate before starting the uninstall. If this switch is not specified then the script will immediately terminate the running processes found.

-Timeout By specifying the number of seconds to wait in conjunction with the -Wait switch, the script will wait for the running Java processes to terminate and if they haven't by the time the timeout is reached then they will be killed by the script.

-Restart If any of the Java programs that are uninstalled return a code of 3010 (restart required) then the script will restart the computer immediately after the completion.

Notes:
The -Wait switch will get the running processes at the time of invocation and wait for all of them to terminate. If new processes are started after the wait period begins then when the first set of processes terminate the script will rerun the query and check for new processes and if found will restart the wait period.

