#!/bin/bash
set -euxo pipefail

# Checks asciidoc file for style and guidelines
asciidocCheck() {
    copyrightRE="// *Copyright *[(][c][)](.*)*$date"
    dateRE=':page-releasedate:[ ]*([0-9]{4}[-][0-9]{2}[-][0-9]{2})[ ]*'
    file=$1
    releaseDateFlag=0
    log=""
    read -r firstline <$file
    if ! [[ $firstline =~ ${copyrightRE} ]]; then
        log+="Add copyright and update year\n"
    fi
    while read line; do
        if [[ $releaseDateFlag -eq 0 ]] && [[ $line =~ $dateRE ]] &&
            [[ "${BASH_REMATCH[1]}" == $(date -r $(date -j -f "%Y-%m-%d" "${BASH_REMATCH[1]}" "+%s") '+%Y-%m-%d') ]]; then
            releaseDateFlag=1
        fi
    done <"$file"
    if [[ $releaseDateFlag -eq 0 ]]; then log+="Add valid release date in the format YYYY-MM-DD\n"; fi
    echo $log
}

file=$1
flag=0
date=$(date +"%Y")
case $file in
*.java)
    copyright="[*] *Copyright *[(][c][)](.*)*$date"
    while read -s line; do
        if [[ $flag -eq 0 && $line =~ ${copyright} ]]; then
            flag=1
        fi
    done <"$file"
    if [ $flag -eq 0 ]; then
        echo "Add copyright and update year"
        # exit 1
    fi
    # awk -v re=$copyright '{if (length($0) > 88) {print NR, $0}; if ($0 ~ re) {print NR, $0}}'
    $(awk '{if (length($0) > 88) {print NR, $0 > "log.out"}}' $file)
    if [[ -s log.out ]]; then
        echo 'The following lines are longer than 88 characters'
        cat log.out
        exit 1
    else echo "All lines are at most 88 characters long"; fi
    ;;
*pom.xml)
    echo "this is a pom $file"
    ;;
*build.graddle)
    echo "this is a graddle $file"
    ;;
*.html)
    copyright="[*] *Copyright *[(][c][)](.*)*$date"
    while read line; do
        if [[ $flag -eq 0 && $line =~ ${copyright} ]]; then
            flag=1
        fi
    done <"$file"
    if [ $flag -eq 0 ]; then
        echo "Add copyright and update year"
        exit 1
    fi
    ;;
*.adoc)
    asciidocCheck $file
    echo "this is the adoc $file"
    ;;
*)
    echo "its something else $file"
    ;;
esac
