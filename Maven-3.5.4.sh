#!/bin/bash

# Function to check if Java is installed
check_java() {
    if type -p java; then
        echo "Java found in PATH."
        _java=java
    elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
        echo "Java found in JAVA_HOME."
        _java="$JAVA_HOME/bin/java"
    else
        echo "Java is not installed. Installing Java..."
        install_java
    fi
}

# Function to install Java
install_java() {
    # Download and install OpenJDK 11 (LTS)
    wget https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz
    tar -xzf openjdk-11+28_linux-x64_bin.tar.gz
    mv jdk-11 /usr/local/

    # Set up environment variables for Java
    echo "export JAVA_HOME=/usr/local/jdk-11" >> ~/.zshrc
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.zshrc

    # Apply the changes
    source ~/.zshrc

    echo "Java installed successfully."
}

# Function to install Maven
install_maven() {
    # Download Maven 3.9.9
    wget https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz

    # Extract the downloaded file
    tar -xzf apache-maven-3.9.9-bin.tar.gz

    # Move the extracted folder to ~/Documents
    mv apache-maven-3.9.9 ~/Documents/

    # Set up environment variables for Maven
    echo "export M2_HOME=~/Documents/apache-maven-3.9.9" >> ~/.zshrc
    echo "export PATH=\$M2_HOME/bin:\$PATH" >> ~/.zshrc

    # Apply the changes
    source ~/.zshrc

    echo "Maven installed successfully."
}

# Check for Java and install if necessary
check_java

# Install Maven
install_maven

# Verify the installation
mvn -version
