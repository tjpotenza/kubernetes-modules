####################################################################################################
# Start - Embedded Copy of cli.sh Shell Utilities, v1.0.0
# (https://github.com/tjpotenza/cli.sh/tree/v1.0.0)

    # If the calling shell is a TTY, certain log messages will be prettified with colors.
    # As this check will always return false both in docker containers AND in subshells,
    # it should be front-loaded in the body of the script's shell itself.
    is_a_tty=""
    if [[ -t 1 ]]; then
        is_a_tty="true"
    fi
    export is_a_tty

    # styled <style_to_apply> <text_to_style>
    #
    # Adds a style to some text to make for more readable logs, but only if the current terminal
    # is a TTY (basically is an interactive terminal that's not a subshell and not being piped).
    # The FORCE_COLOR environment variable may be set to "true" or "1" to force all output to be
    # stylized, regardless of TTY status.
    function styled() {
        local style="${1}"
        local message="${2}"
        local format_start=""
        local format_end="\e[0m"
        case "${style}" in
            "underline")   format_start='\e[4m'; ;;
            "red")         format_start='\033[31m'; ;;
            "red_bold")    format_start='\033[31;1m'; ;;
            "green")       format_start='\033[32m'; ;;
            "green_bold")  format_start='\033[32;1m'; ;;
            "yellow")      format_start='\033[33m'; ;;
            "yellow_bold") format_start='\033[33;1m'; ;;
            "cyan")        format_start='\033[36m'; ;;
            "cyan_bold")   format_start='\033[36;1m'; ;;
            "white")       format_start='\033[37m'; ;;
            "white_bold")  format_start='\033[37;1m'; ;;
        esac
        if [[ "${is_a_tty}" == "true" || "${FORCE_COLOR}" == "true" || "${FORCE_COLOR}" == "1" ]]; then
            printf "%b" "${format_start}${message}${format_end}"
            return 0
        fi
        printf "%b" "${message}"
        return 0
    }

    # log <level (optional)> <message>
    #
    # Prints a plaintext log message at the corresponding log level.  Messages are printed to
    # stderr so that redirecting stdout will only capture the valid output of the utility. The
    # program will immediately terminate with a non-0 status after printing a "FATAL" level log.
    # If only one argument is passed, the level defaults to "INFO".
    function log() {
        local level="${1}"
        local message="${2}"

        # If run with a single argument, just print that as an INFO-level message
        if [[ "${message}" == "" ]]; then
            message="${level}"
            level="info"
        fi

        case "${level}" in
            "debug" )
                printf "%b" "[$(styled "cyan" "DEBUG")] ${message}\n" >&2
            ;;
            "info" )
                printf "%b" "[$(styled "green" "INFO")] ${message}\n" >&2
            ;;
            "warn" )
                printf "%b" "[$(styled "yellow" "WARN")] ${message}\n" >&2
            ;;
            "error" )
                printf "%b" "[$(styled "red" "ERROR")] ${message}\n" >&2
            ;;
            "fatal" )
                printf "%b" "[$(styled "red" "FATAL")] ${message}\n" >&2
                exit 1
            ;;
            "prompt" )
                printf "%b" "[$(styled "yellow" "PROMPT")] ${message}\n" >&2
            ;;
            * )
                printf "%b" "[$(styled "cyan" "${level}")] ${message}\n" >&2
            ;;
        esac
    }

    # prompt <message (optional)> <skip (optional)>
    #
    # Prompts the user for affirmative confirmation before continuing.  A custom message may
    # be specified, and an optional second argument can be passed as "true" to auto-approve
    # and skip the interactive prompt (say by earlier logic or based on an argument to the
    # greater script).  If the calling shell is non-interactive and the prompt was not
    # pre-approved, the prompt will automatically be rejected instead of waiting for
    # input that will never come.
    function prompt() {
        local message="Continue?"
        local skip="false"
        local choice=""

        if [[ "$1" != "" ]]; then
            message="$1"
        fi

        if [[ "$2" != "" ]];then
            skip="$2"
        fi

        log prompt "${message} (y/n)"

        if [[ "${skip}" == "true" ]]; then
            log info "(y) Prompt was pre-approved.  Continuing..."
            return 0
        fi

        if [[ "${is_a_tty}" != "true" ]]; then
            log error "(n) Reached a prompt in a non-interactive shell.  Exiting..."
            return 1
        fi

        read choice
        case "${choice}" in
            y|Y ) log info "Continuing..."; return 0 ;;
            * )   log error "Exiting...";    exit 1 ;;
        esac
    }

# End - Embedded Copy of cli.sh Shell Utilities, v1.0.0
# (https://github.com/tjpotenza/cli.sh/tree/v1.0.0)
#####################################################################################################
