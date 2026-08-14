###############################################################################
# Check Java
###############################################################################

printf "\n"
info "Checking Java installation..."

JAVA_HOME_VALUE=""

###############################################################################
# Method 1 - Existing JAVA_HOME
###############################################################################

if [[ -n "${JAVA_HOME:-}" ]] &&
   [[ -x "$JAVA_HOME/bin/java" ]]; then

    JAVA_HOME_VALUE="$JAVA_HOME"

    success "Java found using JAVA_HOME:"
    echo "       $JAVA_HOME_VALUE"

fi

###############################################################################
# Method 2 - macOS java_home
###############################################################################

if [[ -z "$JAVA_HOME_VALUE" ]]; then

    JAVA_HOME_DETECTED=""

    if JAVA_HOME_DETECTED="$(
        /usr/libexec/java_home 2>/dev/null
    )"; then

        if [[ -n "$JAVA_HOME_DETECTED" ]] &&
           [[ -x "$JAVA_HOME_DETECTED/bin/java" ]]; then

            JAVA_HOME_VALUE="$JAVA_HOME_DETECTED"

            success "Java installation detected:"
            echo "       $JAVA_HOME_VALUE"

        fi

    fi

fi

###############################################################################
# Method 3 - java command
###############################################################################

if [[ -z "$JAVA_HOME_VALUE" ]]; then

    if command -v java >/dev/null 2>&1; then

        JAVA_COMMAND="$(command -v java)"

        if [[ -x "$JAVA_COMMAND" ]]; then

            JAVA_HOME_DETECTED=""

            if JAVA_HOME_DETECTED="$(
                /usr/libexec/java_home 2>/dev/null
            )"; then

                if [[ -n "$JAVA_HOME_DETECTED" ]] &&
                   [[ -x "$JAVA_HOME_DETECTED/bin/java" ]]; then

                    JAVA_HOME_VALUE="$JAVA_HOME_DETECTED"

                    success "Java found:"
                    echo "       $JAVA_HOME_VALUE"

                fi

            fi

        fi

    fi

fi

###############################################################################
# Java NOT Installed
###############################################################################

if [[ -z "$JAVA_HOME_VALUE" ]]; then

    printf "\n"

    printf "%b============================================================%b\n" "$RED" "$NC"
    printf "%b Java is NOT Installed%b\n" "$RED" "$NC"
    printf "%b============================================================%b\n" "$RED" "$NC"

    printf "\n"

    echo "Apache JMeter requires Java to be installed."
    echo
    echo "Please install any approved Java/JDK available"
    echo "through Company Portal."
    echo
    echo "After Java installation:"
    echo
    echo "    1. Close this Terminal"
    echo "    2. Open a new Terminal"
    echo "    3. Run this JMeter installation script again"
    echo

    printf "%b============================================================%b\n" "$YELLOW" "$NC"
    printf "%b Installation stopped - Java is required.%b\n" "$YELLOW" "$NC"
    printf "%b============================================================%b\n" "$YELLOW" "$NC"

    printf "\n"

    exit 1

fi

###############################################################################
# Configure Java
###############################################################################

export JAVA_HOME="$JAVA_HOME_VALUE"
export PATH="$JAVA_HOME/bin:$PATH"

###############################################################################
# Display Java Information
###############################################################################

printf "\n"

info "Java detected successfully."

echo
echo "JAVA_HOME:"
echo "    $JAVA_HOME"

echo
echo "Java version:"

"$JAVA_HOME/bin/java" -version 2>&1

###############################################################################
# Validate Java Executable
###############################################################################

if ! "$JAVA_HOME/bin/java" -version >/dev/null 2>&1; then
    die "Java was detected but could not be executed."
fi

success "Java is working."
