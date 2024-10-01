spin ()
{
	echo -ne "${RED}-"
	echo -ne "${WHITE}\b|"
	echo -ne "${BLUE}\bx"
	sleep .02
	echo -ne "${RED}\b+${NC}"
}


loadRcDir ${HOME}/.bash_functions.d

add2path() {
    # Prompt the user
    read -p "Do you want to add the current directory ($PWD) to PATH? [Y/n]: " answer
    case "$answer" in
        [Nn]* )
            # User selected 'no', prompt for directory to add
            read -p "Enter the full path you want to add to PATH: " new_path
            ;;
        * )
            # Default to adding current directory
            new_path="$PWD"
            ;;
    esac
    # Ensure new_path is not empty
    if [ -z "$new_path" ]; then
        echo "No path provided. Aborting."
        return 1
    fi
    # Resolve to full path
    full_path=$(readlink -f "$new_path")
    # Check if full_path is already in PATH
    if echo "$PATH" | tr ':' '\n' | grep -Fxq "$full_path"; then
        echo "Directory $full_path is already in PATH."
    else
        export PATH="$full_path:$PATH"
        echo "Added $full_path to PATH."
    fi
}

# Add the following to your ~/.bashrc file

# Function to check if we're in a virtual environment
function in_venv() {
    if [ -n "$VIRTUAL_ENV" ]; then
        return 0  # In a virtual environment
    else
        return 1  # Not in a virtual environment
    fi
}

# Function to activate automatic virtual environment creation
function venvon() {
    export VENV_AUTO=1
    echo "Automatic virtual environment activation is ON."
}

# Function to deactivate automatic virtual environment creation
function venvoff() {
    unset VENV_AUTO
    echo "Automatic virtual environment activation is OFF."
}

# Override the pip command
function pip() {
    # Check if VENV_AUTO is enabled and not already in a venv
    if [ -n "$VENV_AUTO" ] && ! in_venv; then
        # Create a virtual environment in the current directory if it doesn't exist
        if [ ! -d "./.venv" ]; then
            echo "Creating virtual environment in ./.venv"
            python3 -m venv ./.venv
            if [ $? -ne 0 ]; then
                echo "Error: Failed to create virtual environment."
                return 1
            fi
        fi
        # Activate the virtual environment
        source ./.venv/bin/activate
        if [ $? -ne 0 ]; then
            echo "Error: Failed to activate virtual environment."
            return 1
        fi
    fi

    # Run the actual pip command
    command pip "$@"
    local PIP_STATUS=$?

    # Check for errors related to virtual environment
    if [ $PIP_STATUS -ne 0 ] && ! in_venv; then
        # Specific error checking can be added here based on pip's output
        if [[ "$@" == "install"* ]]; then
            echo "It seems you're not in a virtual environment. Would you like to create one? (y/n)"
            read -r CREATE_VENV
            if [ "$CREATE_VENV" == "y" ] || [ "$CREATE_VENV" == "Y" ]; then
                # Create a virtual environment
                python3 -m venv ./.venv
                if [ $? -ne 0 ]; then
                    echo "Error: Failed to create virtual environment."
                    return 1
                fi
                # Activate the virtual environment
                source ./.venv/bin/activate
                if [ $? -ne 0 ]; then
                    echo "Error: Failed to activate virtual environment."
                    return 1
                fi
                # Retry the pip command
                command pip "$@"
                return $?
            else
                echo "Continuing without a virtual environment."
            fi
        fi
    fi

    return $PIP_STATUS
}

# Ensure the script is sourced correctly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Please source this script instead of executing it:"
    echo "source ~/.bashrc"
fi




