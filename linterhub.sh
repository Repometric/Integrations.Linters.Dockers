#!/bin/bash

# Constants
Version="0.3"
Prefix="rm"
Start="/bin/sh"
Workdir="/shared"
# Script
Engine="bin/engine.sh"
Storage="bin/storage.sh"
Check="bin/check.sh"

main() {
    # Mode
    case $Mode in
        # Storage commands
        -sb|storage:build)    sh $Storage \
                                --mode build \
                                --instance $Volume \
                                --dockshare $DockShare \
                                --hostshare $HostShare \
                                --path "$Path" \
                              ;;
        -sd|storage:destroy)  sh $Storage \
                                --mode destroy \
                                --instance $Volume \
                                --dockshare $DockShare \
                                --hostshare $HostShare \
                              ;;
        # Engine commands
        -eb|engine:build)     sh $Engine \
                                --mode build \
                                --image $Image \
                                --dock $Dock \
                                --workdir "$Workdir" \
                              ;;
        -ea|engine:analyze)   sh $Engine \
                                --mode analyze \
                                --image $Image \
                                --instance $Instance \
                                --share $Volume \
                                --command "$Command" \
                                --output "$Output" \
                              ;;
        -es|engine:export)    sh $Engine \
                                --mode export \
                                --image $Image \
                              ;;
        # Engine image commands
        -ei|engine:images)    echo "TODO";;
        -eo|engine:online)    echo "TODO";;
        -ef|engine:offline)   echo "TODO";;
        # Engine debug commands
        -er|engine:run)       sh $Engine \
                                --mode run \
                                --image $Image \
                                --instance $Instance \
                                --share $Volume \
                                --start $Start \
                              ;;
        -ee|engine:exec)      sh $Engine \
                                --mode exec \
                                --instance $Instance \
                                --command "$Command" \
                              ;;
        -ed|engine:destroy)   sh $Engine \
                                --mode destroy \
                                --instance $Instance \
                              ;;
        # General commands
        -a|analyze)           analyze;;
        -c|check)             sh $Check;;
        -v|--version|version) echo $Version;;
        -h|--help|help|?|-?)  usage;;
        *)                    echo Unknown command. Try "$0 -help".;;
    esac
}

function parse_args() {
    # VM
    Volume="$Prefix-storage-instance"
    HostShare="HOST_SHARE"
    DockShare="/DOCKER_SHARE"
	echo "Fullcmd: $@"
    while [[ $# -gt 1 ]] 
    do
        key="$1"
        case $key in
            --mode)      Mode="$2";;
            --name)     echo "--- $2" 
						Name="$2"
                         Dock="dockers/alpine/$Name/Dockerfile"
                         Image="$Prefix-$Name-image"
                         Instance="$Prefix-$Name-instance"
                         ;;
            --command)   Command="$2";;
            --start)     Start="$2";;
            --share)     Share="$2";;
            --output)    Output="$2";;
            --workdir)   Workdir="$2";;
            --path)      Path="$2";;
        esac
        shift
        shift
    done
}

# General functions
function analyze()
{
    # Storage session
    Session="12346" #$(date +%s|md5|base64|head -c 8)
    Volume="$Prefix-storage-instance-$Session"
    HostShare="HOST_SHARE_$Session"
    DockShare="/DOCKER_SHARE_$Session"
    # Storage build
    Mode="storage:build"
    main
    # Linters
    IFS='+' read -ra linters <<< "$Name"
	echo "nn $Name"
    for linterPart in "${linters[@]}"; do
        IFS=':' read -ra linter <<< "$linterPart"
        # Linter session
        Name=${linter[0]}
        Dock="dockers/alpine/$Name/Dockerfile"
        Image="$Prefix-$Name-image"
        Instance="$Prefix-$Name-instance-$Session"
        # Linter build
        Mode="engine:build"
        main
        # Linter analyze
        Command=${linter[1]}
		echo "cmd $Command"
		#Command="jshint --reporter checkstyle ./"
		#Command="ls"
        Output="${linter[2]}"
        Mode="engine:analyze"
        main
    done
    # Storage destroy
   Mode="storage:destroy"
   main
}

function usage()
{
cat << EOF
usage: $0 options

OPTIONS:
    setup                         Setup environment.
    analyze                       Perform analysis.
    help                          Display a list of available commands.
    version                       Display the current version of the CLI.

MODES:
    ______________________________ 
    storage:build                 Build storage image with shared volume.
    storage:destroy               Destroy storage image.
    ______________________________
    engine:images                 ToDo.
    engine:offline                ToDo.
    engine:online                 ToDo.
    ______________________________
    engine:build                  Build engine image.
    engine:analyze                Analyze the shared storage volume using engine.
    engine:save                   Save engine image.
    ______________________________
    engine:run                    Run engine image in interactive mode.
    engine:exec                   Execute command in the specified running engine.
    engine:destroy                Destroy engine instance.
    ______________________________ 

EXAMPLES:
    sh linterhub.sh analyze eslint:"eslint *.js":output.txt --path /project/path

    Analyze all js files from --path using eslint linter and save report to output.txt
EOF
}

Args="$@"
if [ "$1" != "--mode" ]; then
    Args="--mode $@"
fi

parse_args $Args
main $Args
exit $?