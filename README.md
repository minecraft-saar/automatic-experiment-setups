# Automatic experiment setup scripts for the minecraft-saar experiment platform

These scripts help you to
 - reproduce our experiment settings
 - create new reproducible settings
 
`functions.sh` provides building blocks to set up a complete system of
broker, minecraft server and architect servers.  The different shell
scripts combine these in different ways.  `master.sh` always runs the
newest version of our software for testing purposes and is a good
starting point for creating an experiment setting.

Some of our software depends on artifacts hosted on GitHub.  To obtain
them, you need to create a personal access token for gradle:
 - go to https://github.com/settings/tokens
 - create a new personal access token with at least the `read:packages` rights
 - add the token and your github user name to your global gradle config:
   `~/.gradle/gradle.properties` needs to have two lines added
   `gpr.user=<your GH username>` and `gpr.key=<the Personal Access Token you created>`
