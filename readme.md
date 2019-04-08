# brshLinuxAnalogs - Various analogs of *nix utils

We all love *nix! It's just the best... well, next to things that are better.

This module is my attempt to recreate various *nix utilities and commands in
PowerShell (on Windows, of course, cuz why would you need to recreate *nix
commands in *nix???).

Currently, the following commands are available:

| Command               | Alias  | Description                                          |
| --------------------- | ------ | ---------------------------------------------------- |
| Get-Calendar          | cal    | Gets a monthly calendar                              |
| Get-CurrentCalendar   | curcal | Get the previous, current, and next month            |
| New-File              | touch  | Create a file and/or mod the access and modify times |
| Start-ElevatedProcess | sudo   | Runs a program as admin                              |
| Start-ElevatedSession | su     | Starts a new PowerShell instance as Admin            |

## cal vs. curcal
cal looks a lot more like the usual *nix cal

curcal adds color and previous and next months

![cal vs. curcal](https://github.com/brsh/brshLinuxAnalogs/blob/master/images/calVScurcal.PNG)

## New-File (touch)
Same basic functionality - can create empty files, can change access and modified timestamps,
but also can create files with timestamp in the name. Just cuz.

## Start-ElevatedProcess vs Start-ElevatedSession
Basic su vs sudo kinda thing here. Start-ElevatedProcess (sudo) starts general processes as
admin. Start-ElevatedSession starts PowerShell sessions as admin.
