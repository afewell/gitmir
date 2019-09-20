#!/bin/bash
echo "starting gitmir run at time: $(date +"%T")" | tee -a /root/gitmirrun.log
gitmirVersion="gitmir-0.10"
echo $gitmirVersion
######## Save initial user inputs in a variable
userInputs="$@"
echo "The user inputs are: $userInputs"

####### Intialize environmental and external variable options
GITMIRROOT=$GITMIRROOT
echo "GITMIRROOT=$GITMIRROOT"
if [ ${#GITMIRROOT} -eq 0 ]
then
{
    echo 'condition: if [ ${#GITMIRROOT} -eq 0 ] matched'
    echo 'setting GITMIRROOT=/usr/local/apache2/htdocs'
    GITMIRROOT=/usr/local/apache2/htdocs
}
fi
echo "GITMIRROOT=$GITMIRROOT"

GITHUBOAUTHTOKEN=$(cat /root/.token)
echo "GITHUBOAUTHTOKEN=$GITHUBOAUTHTOKEN"

######## Declare global variables
orgInput=""
repoInput=""
orgInitialized=0
repoInitialized=0
numParametersEntered=$#
orgGithubCase=""
repoGithubCase=""
orgLowerCase=""
repoLowerCase=""
orgApiUrl=""
repoApiUrl=""

######## Initialize functions
echo "initializing functions at time: $(date +"%T")" | tee -a /root/gitmirrun.log
function flagHandler
# handles flags: calls helpMenu when -h flag passed; returns error message and exits if erroneous flag passed
{
    echo "entering flagHandler function at time: $(date +"%T")" | tee -a /root/gitmirrun.log
    local OPTIND
    while getopts ":hvf:" opt; do
    case "${opt}" in
        h)
        echo "flagHandler case for -h"
        echo "calling helpMenu at time: $(date +"%T")" | tee -a /root/gitmirrun.log
        helpMenu
        exit 0
        ;;
        f)
        echo "flagHandler case for -f"
        echo "calling filehandler $OPTARG at time: $(date +"%T")" | tee -a /root/gitmirrun.log
        fileHandler $OPTARG
        wait
        echo "gitmir has finished processing each of the specified records in the $OPTARG file at time: $(date +"%T")" | tee -a /root/gitmirrun.log
        exit 0
        ;;
        v)
        echo "flagHandler case for -v"
        echo "gitmir version: $gitmirVersion"
        exit 0
        ;;
        ?)
        echo "flagHandler case for -?"
        echo "Invalid Option: -$OPTARG" 1>&2
        exit 1
        ;;
    esac
    done
    shift $((OPTIND-1))
}

function helpMenu
# Echos the help menu to stdout
{
  echo "Thank you for using gitmir, all mirrored repositories can be found at $GITMIRROOT/{org_name}/{repo_name}"
  echo "Usage:"
  echo "    gitmir -h                                                       Display this help message."
  echo "    gitmir -v                                                       Display gitmir version number."
  echo "    gitmir <github_org_name>                                        Github Org (or user) Name. If org name is the only value provided, gitmir will, as appropriate, clone --mirror or remote update & fetch --all for all repos in the org."
  echo "    gitmir <github_user_name>                                       Github Username (or org name). If username is the only value provided, gitmir will, as appropriate, clone --mirror or remote update & fetch --all for all repos users account."
  echo "    gitmir <github_org_name> <github_repo_name>                     Include github repository name and gitmir will, as appropriate, clone --mirror or remote update & fetch --all for a single repository."
  echo "    gitmir  -f <feeder_file_name>                                   Accepts a json file with a list of repos/orgs, gitmir will parse the records and call gitmir for each specified org, or repo. Please see the gitmir readme or exampleFeederFile.json for file format requirements"
  echo "Examples:"
  echo "    gitmir cna-tech                                 This command would, as appropriate, clone --mirror or remote update & fetch --all for every repository within the cna-tech github organization."
  echo "    gitmir cna-tech pks-ninja                       This command would, as appropriate, clone --mirror or remote update & fetch --all for the cna-tech/pks-ninja github repository."
  echo "    gitmir -f exampleFeederFile.json                This command would, as appropriate, clone --mirror or remote update & fetch --all for every org and repository specified in exampleFeederFile.json."
  return
}

function isOrgInitialized
#check if gitmir has already been initialized for the provided org name
{
    # The following if statement sets the orgInitialized value to -1 if org directory present or 0 if org directory not present, as determined by whether a value was returned in the above find commands
    echo "starting isOrgInitialized run at time: $(date +"%T")" | tee -a /root/gitmirrun.log
    echo "input values are: $@" | tee -a /root/gitmirrun.log
    if [ -d "$GITMIRROOT/$orgLowerCase" ]
    then
        echo "gitmir has already initialized the org $orgLowerCase"
        orgInitialized=-1
        echo "the value for orgInitialized is: $orgInitialized"
        return
    else
    echo "gitmir has not yet been initialized for the org $orgLowerCase"
    orgInitialized=0
    echo "the value for orgInitialized is: $orgInitialized"
    return
    fi
}

function initGitmir
# Usage: initGitmir <required_org_name> <optional_repo_name>
{
    echo "starting initGitmir run at time: $(date +"%T")" | tee -a /root/gitmirrun.log
    echo "input values are: $@" | tee -a /root/gitmirrun.log  
    # select case to identify proper workflow for the amount of parameters
    # if $numParametersEntered=1 the only value provided should be the org name
    # if $numParametersEntered=2 both an org name and repo should be the values provided
    case $numParametersEntered in
        1)
            echo "you passed 1 parameter to initGitmir"
            echo "creating the $GITMIRROOT/$orgLowerCase directory"
            mkdir -p $GITMIRROOT/$orgLowerCase
            chown -R daemon:daemon $GITMIRROOT/$orgLowerCase
            echo "beginning cloning for all public repos under github org: $orgLowerCase at time: $(date +"%T")" 
            for repo in $(curl -u $GITHUBOAUTHTOKEN https://api.github.com/orgs/$orgLowerCase/repos?type=public | jq -r '.[].name')
            do
                repo=$(echo "$repo" | tr '[:upper:]' '[:lower:]')
                echo "entering the initGitmir case 1 for repo block"
                echo "executing command: cd $GITMIRROOT/$orgLowerCase"
                cd $GITMIRROOT/$orgLowerCase
                echo "executing command: git clone --mirror https://github.com/$orgLowerCase/$repo.git"
                git clone --mirror https://github.com/$orgLowerCase/$repo.git
                chown -R daemon:daemon $GITMIRROOT/$orgLowerCase/$repo.git
                echo "executing command:cd $GITMIRROOT/$orgLowerCase/$repo.git"
                cd $GITMIRROOT/$orgLowerCase/$repo.git
                echo "Completed initial clone of repo: $repo at time: $(date +"%T")"
                echo "Fetching all branches with git fetch --all"
                git fetch --all
                cp hooks/post-update.sample hooks/post-update
                chmod a+x hooks/post-update
                chown -R daemon:daemon $GITMIRROOT/$orgLowerCase/$repo.git
                git update-server-info
            done
            echo "Completed Cloning Process for all repos and branches in the $orgLowerCase org at time: $(date +"%T")" 
            return
            ;;
        2)
            # if a repo has already been initialized, it will be handled by the updateGitmir function. 
            # accordingly, this function only needs to consider uninitiated repos
            echo "you passed 2 parameters to initGitmir"
            echo "creating the $GITMIRROOT/$orgLowerCase directory"
            mkdir -p $GITMIRROOT/$orgLowerCase
            chown -R daemon:daemon $GITMIRROOT/$orgLowerCase
            cd $GITMIRROOT/$orgLowerCase
            echo "beginning cloning for the $orgLowerCase/$repoLowerCase repository from github at time: $(date +"%T")" 
            git clone --mirror https://github.com/$orgLowerCase/$repoLowerCase.git
            chown -R daemon:daemon $GITMIRROOT/$orgLowerCase/$repo.git
            cd $GITMIRROOT/$orgLowerCase/$repoLowerCase.git
            echo "Completed initial clone of repo: $repoLowerCase at time: $(date +"%T")"
            echo "Fetching all branches with git fetch --all"
            git fetch --all
            cp hooks/post-update.sample hooks/post-update
            chmod a+x hooks/post-update
            git update-server-info
            return
            ;;
    esac
}

function updateGitmir
## updateGitmir updates does a fetch and merge to update orgs that have already been initialized. 
## updateGitmir handles all cases where the org has been initialized. In cases where an org has already been initialized but a desired repo has not been initialized, updateGitmir will 
{
    echo "starting updateGitmir run at time: $(date +"%T")" | tee -a /root/gitmirrun.log
    echo "input values are: $@" | tee -a /root/gitmirrun.log
    # select case to identify proper workflow for the amount of parameters
    # if $numParametersEntered=1 the only value provided should be the org name
    # if $numParametersEntered=2 both an org name and repo should be the values provided
    case $numParametersEntered in
        1)
            echo "you passed 1 parameter to updateGitmir"
            for repo in $(curl -u $GITHUBOAUTHTOKEN https://api.github.com/orgs/$orgLowerCase/repos?type=public | jq -r '.[].name')
            do
                repo=$(echo "$repo" | tr '[:upper:]' '[:lower:]')
                echo "$repo"
                #condition to determine if the repo has already been initialized
                if [ ! -d "$GITMIRROOT/$orgLowerCase/$repo.git" ]
                then
                    echo "the org specified has been initialized, but the repo: $repo has not. Beginning initialization for repo: $repo"
                    echo "beginning cloning for the $orgLowerCase/$repoLowerCase repository from github at time: $(date +"%T")" 
                    git clone --mirror https://github.com/$orgLowerCase/$repoLowerCase.git
                    echo "Completed initial clone of repo: $repoLowerCase at time: $(date +"%T")"
                    chown -R daemon:daemon $GITMIRROOT/$orgLowerCase/$repo.git
                    cd $GITMIRROOT/$orgLowerCase/$repo.git
                    git fetch --all
                    cp hooks/post-update.sample hooks/post-update
                    chmod a+x hooks/post-update
                    chown -R daemon:daemon $GITMIRROOT/$orgLowerCase/$repo.git
                    git update-server-info
                fi
                echo "cd $GITMIRROOT/$orgLowerCase/$repo.git"
                cd $GITMIRROOT/$orgLowerCase/$repo.git
                echo "pwd: $(pwd)"
                echo "Begining git remote update & fetch --all for $orgLowerCase/$repo" 
                git remote update 2>$1 | tee -a /root/gitmirrun.log
                git fetch --all 2>$1 | tee -a /root/gitmirrun.log
                git update-server-info 2>$1 | tee -a /root/gitmirrun.log
            echo "Completed git fetch --all $orgLowerCase/$repo at time: $(date +"%T")" 
            done
            echo "Completed Update Process for all repos and branches in the $orgLowerCase org at time: $(date +"%T")" 
            return
            ;;
        2)
            echo "you passed 2 parameters to updateGitmir"
            cd $GITMIRROOT/$orgLowerCase/$repoLowerCase.git
            echo "Begining git remote update & fetch --all for $orgLowerCase/$repo" 
            git remote update 2>$1 | tee -a /root/gitmirrun.log
            git fetch --all 2>$1 | tee -a /root/gitmirrun.log
            git update-server-info 2>$1 | tee -a /root/gitmirrun.log
            echo "Completed git fetch --all $orgLowerCase/$repo at time: $(date +"%T")" 
            return
            ;;
    esac    
}

function orgExists
# orgExists recieves github org name as a required parameter and branch and/or repo names as optional parameters
# orgExists calls github api to verify org (or repo and branch if provided) exists, if exists continue, else echo error string to stdout and exit 1
# usage: orgExists <github org name>
{
    echo "starting orgExists run at time: $(date +"%T")" | tee -a /root/gitmirrun.log
    echo "input values are: $@" | tee -a /root/gitmirrun.log

    ## Use $orgInput to query the github api which is not case sensitive query, but returns the exact case used by github, which is important for file system operations.
    # If the Org Does Not exist, null value will be returned
    # If $orgInput value provided, get exact case & lower case values
    orgApiUrl="https://api.github.com/orgs/$orgInput"
    echo "$orgApiUrl"
    echo "curl command: curl -u $GITHUBOAUTHTOKEN $orgApiUrl | jq -r '.login'"
    orgGithubCase=$(curl -u $GITHUBOAUTHTOKEN $orgApiUrl | jq -r '.login')
    echo "orgGithubCase=$orgGithubCase"
    orgLowerCase=$(echo "$orgGithubCase" | tr '[:upper:]' '[:lower:]')
    echo "orgLowerCase=$orgLowerCase"

    # If $repoInput value provided, get exact case & lower case values
    if [ $numParametersEntered -eq 2 ]
    then
        # Use $repoInput to query the github api which is not case sensitive query, but returns the exact case used by github, which is important for file system operations.
        # If the Org Does Not exist
        repoApiUrl="https://api.github.com/repos/$orgInput/$repoInput"
        echo "repoApiUrl=$repoApiUrl"
        repoGithubCase=$(curl -u $GITHUBOAUTHTOKEN $repoApiUrl | jq -r '.name')
        repoLowerCase=$(echo "$repoGithubCase" | tr '[:upper:]' '[:lower:]')
        echo "repoLowerCase=$repoLowerCase"
    fi

    # select case to identify proper workflow for the amount of parameters
    # if $numParametersEntered=1 the only value provided should be the org name
    # if $numParametersEntered=2 both an org name and repo should be the values provided
    # if $numParametersEntered=3 an org, repo and branch name should be the values provided
    case $numParametersEntered in
        1)
            echo "you passed 1 parameter to orgExists"
            if [ $orgLowerCase == null ]
            then
                echo 'the org you specified cannot be found, please verify your org name and command syntax and try again. For instructions, please enter "gitmir -h"' 
                exit 1
            elif [ $orgLowerCase != null ]
            then
                echo "the org name you entered has been confirmed, continuing"
                return
            else
                echo "the orgExists function encountered an unknown condition, please see \"gitmir -h\" for instructions on command usage and try again"
                exit 1
            fi
            ;;
        2)
            echo "you passed 2 parameters to orgExists"
            if [ $repoLowerCase == null ]
            then
                echo 'the repo you specified cannot be found, please verify your org name and command syntax and try again. For instructions, please enter "gitmir -h"' 
                exit 1
            elif [ $repoLowerCase != null ]
            then
                echo "the repo name you entered has been confirmed, continuing"
                return
            else
                echo "the orgExists function encountered an unknown condition, please see \"gitmir -h\" for instructions on command usage and try again"
                exit 1
            fi
            ;;
    esac
}

function fileHandler
# This function recieves a file with json formatted gitmir call parameters, processes each record to build a gitmir call for each record, and executes each call
# Usage: fileHandler <filename.json> 
{
    
    echo "starting fileHandler run at time: $(date +"%T")" | tee -a /root/gitmirrun.log
    echo "input values are: $@" | tee -a /root/gitmirrun.log
    echo "cat /root/feederFile.json"
    for line in $(cat $1 | jq -c '.[]')
    do
        echo "entering the fileHandler do loop for line: $line" | tee -a /root/gitmirrun.log
        echo $line
        org=$(echo $line | jq -r '.org')
        org=$(echo "$org" | tr '[:upper:]' '[:lower:]')
        echo "the value entered for org is: $org"
        repo="$2"
        repo=$(echo "$repo" | tr '[:upper:]' '[:lower:]')
        echo "the value entered for repo is: $repo"
        gitmir $org $repo
        wait
    done
}

######## Main Block

## If no parameters entered, or if more than 3 parameters entered, echo error string to stdout, call helpMenu, and exit
echo "the number of parameters entered is $#"
if [ $# -eq 0 ]
# If no parameters entered
then
    # echo error message string, call helpMenu and exit 1
    echo "No User Input Values Detected, please see the following help menu for instructions on proper gitmir command usage"
    helpMenu
    exit 1
elif [ $# -ge 3 ]
# if 3 or more parameters entered
then 
    # echo error message string, call helpMenu and exit 1
    echo "More than 2 parameters were recieved which is invalid, please see the following help menu for instructions on proper gitmir command usage"
    helpMenu
    exit 1
else 
    echo "you entered between 1 and 2 parameters as required, continuing"
fi

## Clear help flag, or any erroneous flags
# The "$@" value passed to flagHandler below reflects the user input entered when gitmir was called, which passes the user input to the flagHandler function
flagHandler "$@"
echo "you made it past flagHandler"

## After help calls cleared above, we can now assign the user inputs to their corresponding global variables:
echo "at least 1 parameter entered and no flags set, assigning user inputs to variables:"
orgInput="$1" 
echo "the value entered for org is: $orgInput"
repoInput="$2"
echo "the value entered for repo is: $repoInput"
numParametersEntered=$#
echo the "value for numParametersEntered is: $#" 
# the numParametersEntered variable should be populated with the number of parameters entered by the user when gitmir was called
# per usage guidelines, if 1 parameter entered it should be the github org, if 2 parameters, should be org and repo

## Confirm that the org, repo (if provided) and branch (if provided) exist, if not return error string and exit 1, if exist initialize updated variables with exact github case
echo "beginning orgExists check, calling orgExists $orgInput $repoInput"
orgExists $orgInput $repoInput
echo "you have passed the orgExists function check"


## call the isOrgInitialized function which sets the $orgInitialized=-1 if org has been initialized, else sets $orgInitialized=0
echo "calling: isOrgInitialized $orgLowerCase"
isOrgInitialized $orgLowerCase
echo "orgInitialized=$orgInitialized"
echo "you passed the org initializitation check block"

#### Run Block
echo "entering the run block"
## run the appropriate initGitmir or updateGitmir function call for the parameters entered
if [ $orgInitialized -eq 0 ]
# This if block runs if the org has not yet been initialized
then
    echo "the run block says the org has not been initialized"
    echo "calling initGitmir $orgLowerCase $repoLowerCase"
    initGitmir $orgLowerCase $repoLowerCase
    wait
    echo "gitmir has completed initialization of $orgLowerCase $repoLowerCase"
    exit 0
elif [ $orgInitialized -eq -1 ]
# this if block runs if the org has been initialized
then
    echo "the run block says the org you entered: $orgLowerCase has been initialized"
    echo "calling updateGitmir $orgLowerCase $repoLowerCase to remote update or, if needed, clone the specified repository"
    updateGitmir $orgLowerCase $repoLowerCase
    wait
    echo "gitmir has updated the requested $orgLowerCase $repoLowerCase"
    exit 0
else
    echo "the orgExists function encountered an unknown condition, please see \"gitmir -h\" for instructions on command usage and try again"
    exit 1
fi

echo "you made it to the end of the main block without hitting an exit point so some loop isnt closed, exiting now"
exit 1
