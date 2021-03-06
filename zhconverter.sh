#!/bin/sh -

ARGV=$(getopt -o 't:h' -l 'to-code:,help' -n "${0}" -- "$@")
eval set -- "$ARGV"

print_usage() {
    printf '%s\n' \
            "Usage: ${0} [OPTION...] [FILE...]" \
            'Convert Simplified Chinese to Traditional Chinese' \
            'or convert Traditional Chinese to Simplified Chinese by MediaWiki API.' \
            '' \
            'Options:' \
            ' -t, --to-code=NAME        Set langage for output! at this you can use zh-cn,' \
            '                           zh-hans, zh-hant, zh-hk, zh-sg or zh-tw(default).' \
            ' -h, --help                Show this help list.'
}

print_error() {
    local my_name="${0}"
    printf '%s\n' \
            "${my_name}: missing optstring argument" \
            "Try \`${my_name} --help' for more information." 1>&2
}

convert_chinese() {
    local mediawiki_api='https://zh.wikipedia.org/w/api.php'
    local mediawiki_data='action=parse&format=json&prop=text&disablepp=true&uselang='
    local mediawiki_return_substitute='s/^.*"text":{"\*":"<pre>\\n\(.*\)\\n<\\\/pre>\\n"}}}$/\1/'
    local mediawiki_uselang="${1}"
    shift
    printf '%b' \
                $(sed -e 's/&/\&amp;/;' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/{/\&#123;/g' -e 's/}/\&#125;/g' \
                -e '1i\<pre>-{}-' -e '$a\</pre>' "$@" | \
                curl -s -d "${mediawiki_data}${mediawiki_uselang}" --data-urlencode "text@-" "$mediawiki_api" | \
                sed -e "$mediawiki_return_substitute" -e 's/&#125;/}/g' -e 's/&#123;/{/g' \
                    -e 's/&gt;/>/g' -e 's/&lt;/</g' -e 's/&amp;/\&/;' -e 's/ /\\u0020/g') | \
        sed -e 's;\\\/;/;g'
}

main() {
    local mediawiki_uselang='zh-tw'
    while true
    do
        case "${1}" in
            '-t'|'--to-code')
                mediawiki_uselang="${2}"
                shift 2
                ;;
            '-h'|'--help')
                print_usage
                break
                ;;
            '--')
                shift
                convert_chinese "$mediawiki_uselang" "$@"
                break
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
