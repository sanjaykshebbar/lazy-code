#!/bin/bash

# Function to print messages with color
print_message() {
    local message="$1"
    local color="$2"
    echo -e "\033[${color}m${message}\033[0m"
}

# Timer function that will run in the background
show_timer() {
    SECONDS=0
    while true; do
        printf "\rTime elapsed: %02d:%02d:%02d" $(($SECONDS / 3600)) $(($SECONDS % 3600 / 60)) $(($SECONDS % 60))
        sleep 1
    done
}

# Function to clear system caches
clear_system_caches() {
    print_message "Clearing system caches..." "33"  # Yellow for info
    rm -rf ~/Library/Caches/*
    if [ $? -eq 0 ]; then
        print_message "System caches cleared." "32"  # Green for success
    else
        print_message "Error clearing system caches." "31"  # Red for error
    fi
}

# Function to clear application logs
clear_app_logs() {
    print_message "Clearing application logs..." "33"
    rm -rf ~/Library/Logs/*
    if [ $? -eq 0 ]; then
        print_message "Application logs cleared." "32"
    else
        print_message "Error clearing application logs." "31"
    fi
}

# Function to clear browser caches
clear_browser_caches() {
    print_message "Clearing browser caches..." "33"
    rm -rf ~/Library/Safari/*
    rm -rf ~/Library/Application\ Support/Google/Chrome/Default/Cache/*
    rm -rf ~/Library/Application\ Support/Firefox/Profiles/*.default-release/cache2/*
    if [ $? -eq 0 ]; then
        print_message "Browser caches cleared." "32"
    else
        print_message "Error clearing browser caches." "31"
    fi
}

# Function to clear trash
clear_trash() {
    print_message "Emptying the Trash..." "33"
    
    # Check if the Trash path exists and is not empty
    if [ -d "$HOME/.Trash" ] && [ "$(ls -A $HOME/.Trash)" ]; then
        sudo rm -rf ~/.Trash/*
        if [ $? -eq 0 ]; then
            print_message "Trash emptied." "32"
        else
            print_message "Error emptying the Trash." "31"
        fi
    else
        print_message "Trash is already empty." "32"
    fi
}


# Function to clear downloads
clear_downloads() {
    print_message "Clearing Downloads folder..." "33"
    rm -rf ~/Downloads/*
    if [ $? -eq 0 ]; then
        print_message "Downloads folder cleared." "32"
    else
        print_message "Error clearing Downloads folder." "31"
    fi
}

# Function to clear mail downloads
clear_mail_downloads() {
    print_message "Clearing Mail downloads..." "33"
    rm -rf ~/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads/*
    if [ $? -eq 0 ]; then
        print_message "Mail downloads cleared." "32"
    else
        print_message "Error clearing Mail downloads." "31"
    fi
}

# Main function to run all cleanup tasks
main() {
    # Start the timer in the background
    show_timer &
    timer_pid=$!
    
    clear_system_caches
    clear_app_logs
    clear_browser_caches
    clear_trash
    clear_downloads
    clear_mail_downloads
    
    # Kill the timer process
    kill $timer_pid
    
    print_message "All junk files cleared." "32"
    print_message "Cleanup completed in $(($SECONDS / 3600)) hours $(($SECONDS % 3600 / 60)) minutes $(($SECONDS % 60)) seconds." "32"
}

# Run the main function
main
