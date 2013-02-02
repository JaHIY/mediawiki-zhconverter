#!/bin/sh -

ARGV=$(getopt -o 't:h' -l 'to-code:,help' -n "$0" -- "$@")
eval set -- "$ARGV"

print_usage() {
    printf '%s\n' \
            "Usage: ${0} [OPTION...] [FILE...]" \
            'Convert Simplified Chinese to Traditional Chinese or convert Traditional Chinese to Simplified Chinese by MediaWiki API.' \
            '' \
            'Options:' \
            ' -t, --to-code=NAME        Set langage for output! at this you can use zh-cn, zh-hans, zh-hant, zh-hk, zh-sg or zh-tw(default)' \
            ' -h, --help                 Show this help list.'
}

print_error() {
    local my_name="${0}"
    printf "${my_name}: missing optstring argument\nTry \`${my_name} --help' for more information.\n" 1>&2
}

convert_chinese() {
    local AWK_SYNTAX='BEGIN{print "<pre>-{}-"}{print $0}END{print "</pre>"}'
    local MEDIAWIKI_API='http://zh.wikipedia.org/w/api.php'
    local MEDIAWIKI_DATA='action=parse&format=json&prop=text&disablepp=true&uselang='
    local MEDIAWIKI_RETURN_SUBSTITUTE='s/^.*"text":{"\*":"<pre>\\n\(.*\)\\n<\\\/pre>\\n"}}}$/\1/'
    local MEDIAWIKI_USELANG="${1}"
    shift
    printf '%b' $(sed -e 's/&/\&amp;/;' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/{/\&#123;/g' -e 's/}/\&#125;/g' "$@" | awk "$AWK_SYNTAX" | curl -s -d "${MEDIAWIKI_DATA}${MEDIAWIKI_USELANG}" --data-urlencode "text@-" "$MEDIAWIKI_API" | sed -e "$MEDIAWIKI_RETURN_SUBSTITUTE" -e 's/&#125;/}/g' -e 's/&#123;/{/g' -e 's/&gt;/>/g' -e 's/&lt;/</g' -e 's/&amp;/\&/;') | sed -e 's;\\\/;/;g'
}

main() {
    local MEDIAWIKI_USELANG='zh-tw'
    while true
    do
        case "${1}" in
            '-t'|'--to-code')
                MEDIAWIKI_USELANG="${2}"
                shift 2
                ;;
            '-h'|'--help')
                print_usage
                break
                ;;
            '--')
                shift
                if [ $# -gt 0 ]
                then
                    convert_chinese "$MEDIAWIKI_USELANG" "$@"
                    break
                else
                    print_error
                    return 2
                fi
                ;;
            *)
                print_error
                return 1
                ;;
        esac
    done
    return 0
}

main "$@"
