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
    # Download Maven 3.5.4
    wget https://archive.apache.org/dist/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.zip

    # Extract the downloaded file
    unzip apache-maven-3.5.4-bin.zip

    # Move the extracted folder to /usr/local
    mv apache-maven-3.5.4 /usr/local/

    # Set up environment variables for Maven
    echo "export M2_HOME=/usr/local/apache-maven-3.5.4" >> ~/.zshrc
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
