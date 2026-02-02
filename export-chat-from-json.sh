#!/bin/sh

set -e
cd "$(dirname "$0")"

show_usage() {
	cat <<-EOF
	Usage: ${0} [OPTIONS]

	Options:
	  -f, --file <file>       Specify input JSON file (default: auto-detect copilot_export_*.json)
	  -s, --session <id>      Extract a specific session to markdown
	  -o, --output <file>     Output file for extracted session (default: <id>.md)
	  -l, --list              List all chat sessions with dates and first user message
	  -h, --help              Show this help message
	EOF
}

get_combined_json() {
	input_file="${1}"
	
	if [ "${input_file}" != "" ]; then
		if [ ! -f "${input_file}" ]; then
			echo "Error: File '${input_file}' not found" >&2
			exit 1
		fi
		cat "${input_file}"
		return
	fi
	
	# Auto-detect and combine all copilot_export JSON files
	found_files=""
	for file in copilot_export_*.json; do
		if [ -f "${file}" ]; then
			found_files="${found_files} ${file}"
		fi
	done
	
	if [ "${found_files}" = "" ]; then
		echo "Error: No copilot_export_*.json file found in current directory" >&2
		exit 1
	fi
	
	# Combine all files and deduplicate by key+session
	jq -s 'add | unique_by(.key + "-" + .content.session)' ${found_files}
}

list_sessions() {
	combined_json="$(get_combined_json "${1}")"
	
	# Color codes
	BOLD="\033[1m"
	CYAN="\033[36m"
	GREEN="\033[32m"
	YELLOW="\033[33m"
	WHITE="\033[97m"
	ORANGE="\033[38;5;208m"
	RESET="\033[0m"
	
	echo "Chat Sessions from combined data"
	echo "================================"
	echo ""
	
	# Extract and format session data
	sessions_data="$(printf '%s' "${combined_json}" | jq -r '
		[.[] | select(.key == "conversation-1") | {
			key: .key,
			session: .content.session,
			date: .content.date,
			human: .content.human
		}] | unique_by(.session) | sort_by(.date) | reverse | .[] | @base64
	')"
	
	session_num=1
	
	for session_data_b64 in ${sessions_data}; do
		session_data="$(printf '%s' "${session_data_b64}" | base64 -d)"
		
		session_id="$(printf '%s' "${session_data}" | jq -r '.session')"
		date="$(printf '%s' "${session_data}" | jq -r '.date')"
		human_msg="$(printf '%s' "${session_data}" | jq -r '.human')"
		
		# Replace newlines with spaces and squeeze multiple spaces
		human_msg="$(printf '%s' "${human_msg}" | tr '\n' ' ' | tr -s ' ')"
		
		# Truncate long messages
		if [ "${#human_msg}" -gt 200 ]; then
			human_msg="$(printf '%s' "${human_msg}" | head -c 197)..."
		fi
		
		printf "${BOLD}${CYAN}%d. Session: %s${RESET}\n" "${session_num}" "${session_id}"
		printf "${GREEN}   Date: %s${RESET}\n" "${date}"
		printf "${WHITE}   First message: ${ORANGE}%s${RESET}\n" "${human_msg}"
		printf "\n"
		printf "${YELLOW}────────────────────────────────────────────────────────────────${RESET}\n"
		printf "\n"
		
		session_num=$((session_num + 1))
	done
}

extract_session() {
	combined_json="$(get_combined_json "${1}")"
	session_id="${2}"
	output_file="${3}"
	
	if [ "${session_id}" = "" ]; then
		echo "Error: Session ID required for --session" >&2
		exit 1
	fi
	
	if [ "${output_file}" = "" ]; then
		output_file="${session_id}.md"
	fi
	
	echo "Extracting session '${session_id}' from combined data..."
	
	# Extract all conversations for the session, sorted by conversation number
	conversations_data="$(printf '%s' "${combined_json}" | jq -r --arg session "${session_id}" '
		[.[] | select(.content.session == $session)] | 
		sort_by(.key | sub("conversation-"; "") | tonumber) | 
		.[] | @base64
	')"
	
	if [ "${conversations_data}" = "" ]; then
		echo "Error: No conversations found for session '${session_id}'" >&2
		exit 1
	fi
	
	# Get the date from conversation-1
	first_date="$(printf '%s' "${combined_json}" | jq -r --arg session "${session_id}" '
		.[] | select(.content.session == $session and .key == "conversation-1") | .content.date
	')"
	
	# Start writing the markdown file
	{
		printf "# Chat Session: %s (%s)\n\n" "${session_id}" "${first_date}"
		
		for conv_data_b64 in ${conversations_data}; do
			conv_data="$(printf '%s' "${conv_data_b64}" | base64 -d)"
			
			date="$(printf '%s' "${conv_data}" | jq -r '.content.date')"
			human="$(printf '%s' "${conv_data}" | jq -r '.content.human')"
			copilot="$(printf '%s' "${conv_data}" | jq -r '.content.copilot')"
			
			printf "### 👤 %s\n\n" "${human}"
			
			printf "> ### 🤖 Copilot\n"
			printf "> \n"
			printf '%s\n' "${copilot}" | sed 's/^/> /'
			printf "\n"
			
			printf -- "---\n\n---\n\n---\n\n---\n\n---\n\n"
		done
	} > "${output_file}"
	
	echo "Session extracted to: ${output_file}"
}

# Main script logic
if [ "$#" -eq 0 ]; then
	show_usage
	exit 0
fi

# Parse arguments
input_file=""
session_id=""
output_file=""
action=""

while [ "$#" -gt 0 ]; do
	case "${1}" in
		-f|--file)
			input_file="${2}"
			shift 2
			;;
		-s|--session)
			action="extract"
			session_id="${2}"
			shift 2
			;;
		-o|--output)
			output_file="${2}"
			shift 2
			;;
		-l|--list)
			action="list"
			shift
			;;
		-h|--help)
			show_usage
			exit 0
			;;
		*)
			echo "Error: Unknown option '${1}'" >&2
			echo "" >&2
			show_usage
			exit 1
			;;
	esac
done

case "${action}" in
	list)
		list_sessions "${input_file}"
		;;
	extract)
		extract_session "${input_file}" "${session_id}" "${output_file}"
		;;
	"")
		show_usage
		exit 0
		;;
	*)
		echo "Error: Unknown action '${action}'" >&2
		exit 1
		;;
esac
