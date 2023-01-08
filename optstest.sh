function usage {
  echo "..."
}

while getopts "hvu::" ARG; do
  case $ARG in
      v) # Specify v value.
        echo "Read Verfication Enabled!"
        ;;
      u) # Specify strength, either 45 or 90.
        SINLGEMODE="${OPTARG}"
        echo "Single user mode enabled."
        ;;
      h) # Display help.
        usage
        exit 0
        ;;
    esac
done
