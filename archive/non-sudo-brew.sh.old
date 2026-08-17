#!/bin/zsh

# Variables
HOMEBREW_DIR="$HOME/homebrew"
ZSHRC_FILE="$HOME/.zshrc"
BREW_INSTALL_URL="https://bit.ly/brew-mac"


# Step 2: Create Homebrew directory in the user's home directory
echo "Creating Homebrew directory at $HOMEBREW_DIR..."
mkdir -p "$HOMEBREW_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to create Homebrew directory."
    exit 1
fi
echo "Homebrew directory created successfully."

# Step 3: Download and extract Homebrew
echo "Downloading and extracting Homebrew..."
curl -L "$BREW_INSTALL_URL" | tar xz --strip 1 -C "$HOMEBREW_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to download or extract Homebrew."
    exit 1
fi
echo "Homebrew installed successfully at $HOMEBREW_DIR."

# Step 4: Update .zshrc with the Homebrew path
echo "Updating $ZSHRC_FILE with Homebrew path..."
echo 'export PATH="/Users/$USER/homebrew/bin:$PATH"' >> "$ZSHRC_FILE"
if [ $? -ne 0 ]; then
    echo "Failed to update $ZSHRC_FILE."
    exit 1
fi

# Step 5: Source .zshrc to apply changes
echo "Applying changes to the current shell..."
source "$ZSHRC_FILE"
if [ $? -ne 0 ]; then
    echo "Failed to apply changes from $ZSHRC_FILE. Please source it manually."
    exit 1
fi

echo "Homebrew setup is complete, and the path is now active in the current shell."

