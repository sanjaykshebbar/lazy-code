#!/bin/bash

# Download Maven 3.5.4
wget https://archive.apache.org/dist/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.zip

# Extract the downloaded file
unzip apache-maven-3.5.4-bin.zip

# Move the extracted folder to /usr/local
sudo mv apache-maven-3.5.4 /usr/local/

# Set up environment variables
echo "export M2_HOME=/usr/local/apache-maven-3.5.4" >> ~/.bash_profile
echo "export PATH=\$M2_HOME/bin:\$PATH" >> ~/.bash_profile

# Apply the changes
source ~/.bash_profile

# Verify the installation
mvn -version
