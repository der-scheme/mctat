#!/bin/bash
#
#    Tools for Minecraft Texture Artists
#    Copyright (c) 2012 - 2015 Sebastian Dufner
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

name='Tools for Minecraft Texture Artists'
version='1.1'

uname=`uname`
mcpath="$HOME/.minecraft"
mclauncherpath="/opt/minecraft/bin"
if [[ $uname =~ "^CYGWIN.*$" ]] || [[ $uname =~ "^.*W|windows.*$" ]] || [[ $uname =~ "^.*NT.?6\..*$" ]]
then
    uname=Windows
    mcpath="$APPDATA/.minecraft"
    mclauncherpath="$PROGRAMFILES/minecraft"
elif [[ $uname = Darwin ]]
then
    mcpath="$HOME/Library/Application Support/minecraft"
fi

if [ -z "$MCLAUNCHER" ]
then
    MCLAUNCHER="$mclauncherpath/minecraft.jar"
fi

indent_width=6
this=$0

clean ()
{
    if [ -e .mctat ]
    then
        rm -rf .mctat
    fi
}

help ()
{
    echo

    case "$1" in
        clean)
            echo "Usage: $this clean"
            echo
            echo "Removes the temporary production files."
            ;;
        help)
            echo "Usage: $this help COMMAND"
            echo
            echo "Displays the help page for the specified COMMAND."
            ;;
        pack|watch)
            echo "Usage: $this $1 [OPTION...]"
            echo
            if [[ $1 = watch ]]
            then
                echo "Watches the current directory for changes and, if a change on a graphics"
                echo -n "container happens, c"
            else
                echo -n "C"
            fi
            echo -n "reates a texture pack (zip file) of the recognized contents in the current"
            if [[ $1 = watch ]]
            then
                echo -n ' '
            else
                echo
            fi
            echo -n "directory. The zip file will be named after the current"
            if [[ $1 = watch ]]
            then
                echo
            else
                echo -n ' '
            fi
            echo "directory."
            echo
            echo "NOTE:"
            echo "  In order to have a texture packed into the zip file, you need to have an"
            echo "  associated graphics container. (i.e.: terrain.png will only be included if"
            echo "  there is a terrain.xcf or terrain.psd)"
            echo
            echo "WARNING:"
            echo "  The options -u and -p allow you to specify your Minecraft username and"
            echo "  password. Though your credentials won't be stored, or transmitted to anyone,"
            echo "  you may use these options only at your own risk!"
            echo
            echo "OPTIONs:"
            echo "  -d DIR"
            indent "Use this option to override the default path to your Minecraft profile."
            echo
            indent "NOTE:"
            indent "  Use this in combination with -a, if, for some reason, the script"
            indent "  fails to correctly determine your Minecraft profile directory."
            echo "  -m"
            indent "Automatically moves the texture pack to Minecraft's default texture pack"
            indent "directory."
            echo "  -p PASSWORD"
            indent "The PASSWORD that will be passed to the Minecraft client. Will be ignored"
            indent "if -r is not active."
            echo "  -r"
            indent "Runs Minecraft after packing using the alias minecraft. If it is not"
            indent "available, $this will run $MCLAUNCHER."
            indent "You can change this behaviour by assigning the variable \$MCLAUNCHER the"
            indent "path of your choice."

            if [ $uname == Windows ]
            then
                echo
                indent "NOTE:"
                indent "  For simplicity, this script will always try to run the platform-"
                indent "  independent minecraft.jar (not to be confused with the minecraft.jar in"
                indent "  your Minecraft profile directory) instead of the minecraft.exe, which "
                indent "  can be downloaded from http://www.minecraft.net/download ."
            fi
            echo "  -u USERNAME"
            indent "The USERNAME that will be passed to the Minecraft client. Will be ignored"
            indent "if -r is not active."
            ;;
        status)
            echo "Usage: $this status [OPTION] "
            echo
            echo "Displays status information about the current directory."
            echo "By default this information includes only the graphics containers that changed"
            echo "since the last pack operation. If there weren't any, $this will list all"
            echo "recognized files."
            echo
            echo "NOTE:"
            echo "  All filepaths are relative to DIR."
            echo
            echo "OPTIONs:"
            echo "  -a"
            indent "Recursively lists all files recognized by $this."
            indent "Cannot be used with -l."
            echo "  -l"
            indent "Lists all files that were packed in the last pack operation."
            indent "Cannot be used with -a."
            echo "  -t"
            indent "Lists all mcmeta files."
            ;;
        version)
            echo "Usage: $this version"
            echo
            echo "Displays detailed version, license and contact information."
            ;;
        *)
            echo "help: Unknown command: $1" >&2
            ;;
    esac

    exit 1
}

indent ()
{
    width=$indent_width
    if [ $# -gt 1 ]
    then
        width=$2
    fi

    printf "%${width}s$1\n" ' '
}

list_files ()
{
    # echo "`find | grep -E '.*\.(xcf|psd)' | xargs stat -c \"%Y %n\"`"
    echo "`find -not -iwholename './.mctat*' | grep -E '.*\.(xcf|psd|mcmeta)' | xargs -d '\n' md5sum`"
}

list_txts ()
{
    echo "`find -name '*.mcmeta' -not -iwholename './.mctat*'`"
}

modified_files ()
{
    mkdir -p ./.mctat
    tmpfile=./.mctat/.files_new
    list_files > $tmpfile 2> /dev/null

    if [ -f ./.mctat/.files ]
    then
        echo "`diff ./.mctat/.files $tmpfile | awk '/^>/ { print $3 }' | sort`"
    else
        echo "`cat ./.mctat/.files_new | awk '{ print $2 }' | sort`"
    fi
}

reset_status ()
{
    mv -f ./.mctat/.files_new ./.mctat/.files
}

pack ()
{
    files=`modified_files`
    allfiles=`all=0;status | sed -r 's/(xcf|psd)$/png/g' | tr '\n' ' '`
    filescount=$(( `echo "$files" | wc -l` - 0 ))

    if [ `echo "$files" | wc -L` -eq 0 ]
    then
        filescount=0
    fi

    if [ $filescount -gt 0 ]
    then
        echo "Found $filescount modified or new files:"
        echo "$files"
        echo
        echo "Processing..."

        if [ -f "./pack.mcmeta" ]
        then
            archive="./pack.mcmeta"
            cp -f ./pack.mcmeta ./.mctat/pack.mcmeta
        fi
        if [ -f "./LICENSE" ]
        then
            archive="$archive LICENSE"
            cp -f ./LICENSE ./.mctat/LICENSE
        fi

        archivename="`basename $(pwd)`.zip"
        filemap=

        for file in $files
        do
            target=`echo "$file" | sed -r 's/(xcf|psd)$/png/g'`

            echo "\"$file\" => \"$target\""
            mkdir -p `dirname ".mctat/$target"`

            if [ ${file: -7} == ".mcmeta" ]
            then
                cp -f "$file" ".mctat/$file"
            else
                filemap="$filemap \"$file\" \".mctat/$target\""
            fi
        done

        script="
            (define (convert-files filenames)
                (cond
                  ((null? filenames)
                   (gimp-quit 0))
                  (else
                   (let*
                       ((image (car (gimp-file-load RUN-NONINTERACTIVE (car filenames) (car filenames))))
                        (layer (car (gimp-image-merge-visible-layers image CLIP-TO-IMAGE))))
                     (gimp-file-save RUN-NONINTERACTIVE image layer (cadr filenames) (cadr filenames))
                     (convert-files (cddr filenames))))))
            (convert-files '($filemap))"
        gimp-console -nb "$script" 2> /dev/null

        echo
        echo "Compressing..."
        cd .mctat
        echo $archive
        zip ../"$archivename" $archive $allfiles
        cd ..
        reset_status

        if [ $move -eq 0 ]
        then
            mkdir -p "$mcdir/resourcepacks"
            mv -vf "$archivename" "$mcdir/resourcepacks/$archivename"
        fi

        if [ $runmc -eq 0 ]
        then
            echo
            echo "Running Minecraft."

            if type minecraft
            then
                minecraft "--username=\"$username\" --password=\"$password\""
            else
                java -jar "$MCLAUNCHER --username=\"$username\" --password=\"$password\""
            fi
        fi

        echo
        echo "Successfully created $archivename!"
    fi
}

print_usage ()
{
    echo
    echo "Usage: $this COMMAND [OPTIONS] [PARAMS]"
    echo
    echo "Most commands accept a directory parameter. If no directory is specified,"
    echo "$0 will use the current working directory."
    echo
    echo "COMMANDs:"
    echo "  clean"
    indent "Removes all temporary production files in the current dicrectory."
    echo "  help COMMAND"
    indent "Displays the help page for the specified COMMAND."
    echo "  pack [OPTION...]"
    indent "Creates a texture pack of the contents in the current directory."
    echo "  status [OPTION]"
    indent "Displays status information about the current directory."
    echo "  version"
    indent "Displays detailed version, license and contact information."
    echo "  watch [OPTION...]"
    indent "Watches the current directory for changes and calls 'pack' if a change"
    indent "happens."

    exit 1
}

print_version ()
{
    echo "'$name $version' Copyright (c) 2012 - 2015 Sebastian Dufner"
    echo "This program comes with ABSOLUTELY NO WARRANTY. This is free software, and you"
    echo "are welcome to redistribute it under the terms of the GNU General Public"
    echo "License."
}

print_version_long ()
{
    print_version
    echo "You should have received a copy of the GNU General Public License along with"
    echo "this program.  If not, see <http://www.gnu.org/licenses/>."
    echo
    echo "If you have any questions, suggestions, patches or bug reports, feel free to"
    echo "contact me on the Minecraft forum."
    echo "Forum thread:"
    echo "  http://asd"
    echo "Forum user:"
    echo "  http://asd"
}

status ()
{
    if [ $all -eq 0 ]
    then
        list_files | awk '{ print $2 }'
    elif [ $last -eq 0 ] || [ $txt -eq 0 ]
    then
        if [ $last -eq 0 ]
        then
            if [ -f ./.mctat/.files ]
            then
                cat ./.mctat/.files | awk '{ print $2 }'
            fi
        elif [ $txt -eq 0 ]
        then
            list_txts
        fi
    else
        modified_files
    fi
}

watch ()
{
    echo 'Watching directory... Press Ctrl+C to terminate.'
    while echo -n
    do
        pack

        sleep 1
    done
}

case "$1" in
    clean)
        shift
        clean "$@"
        ;;

    help)
        print_version

        if [ $# -gt 1 ]
        then
            help $2
        else
            print_usage
        fi
        ;;
    pack|watch)
        command=$1
        shift

        move=1
        mcdir="$mcpath"
        password=
        runmc=1
        username=

        while getopts ':md:p:ru:' opt
        do
            case $opt in
                d)
                    mcdir="$OPTARG"
                    ;;
                m)
                    move=0
                    ;;
                p)
                    password="$OPTARG"
                    ;;
                r)
                    runmc=0
                    ;;
                u)
                    username="$OPTARG"
                    ;;
                \?)
                    echo "Invalid option: -$OPTARG" >&2
                    help pack
                    ;;
                :)
                    echo "Option -$OPTARG requires an argument." >&2
                    help pack
                    ;;
            esac
        done

        $command
        ;;
    status)
        shift

        all=1
        last=1

        while getopts ":alt" opt
        do
            case $opt in
                a)
                    all=0
                    ;;
                l)
                    last=0
                    ;;
                t)
                    txt=0
                    ;;
                \?)
                    echo "Invalid option: -$OPTARG" >&2
                    help status
                    ;;
            esac
        done

        status
        ;;
    version|"--version")
        print_version_long
        ;;
    *)
        print_version
        print_usage
        ;;
esac
