#!/bin/bash

# Description: Installs Visual Studio Code 
# Parameters: Nothing
# Returns: 0 if vs-code was successfully installed, 1 if vs-code could not be installed 
function install_vscode {
	local status=
    
	echo -e "\n------------------------------"
    echo "------Installing VS-Code------"
    echo "------------------------------"

	# Install VS-Code if not installed on the system 
	if ! which code > /dev/null; then
		sudo apt update && sudo apt upgrade
		sudo apt install software-properties-common apt-transport-https wget -y
		wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
		sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
		sudo apt update

		if ! sudo apt install code; then
			echo "[*] ERROR: Failed to install Visual Studio Code" > /dev/stderr  
			status=1
		else
			echo "[*] SUCCESS: Visual Studio Code Installed"
		fi
		status=0
	else
		echo "[*] INFO: VS-Code is already installed, skipping install..."
		status=0
	fi
	return "$status"
}

# Description: Installs docker using apt package manager
# Parameters: username of the logged in user
# Returns: 0 if docker was successfully installed, one if docker could not be installed
function install_docker {
	local user=$1
	local groups=
	local status=

	echo -e "\n------------------------------"
	echo "-------Installing Docker------"
    echo "------------------------------"

	# If docker is not installed, install docker using apt	
	if ! which docker > /dev/null; then
		sudo apt update && sudo apt upgrade -y
		if ! sudo apt install docker.io -y; then
			echo "[*] ERROR: Unable to install docker" > /dev/stderr
			status=1
		else
			echo "[*] SUCCESS: Docker Successfully Installed"
			status=0
		fi
	else
		echo "[*] INFO: Docker is already installed, skipping install..."
		status=0
	fi

	if ((status == 0)); then
		# Store all the groups the user is apart of in the variable for later checking
		groups=$(grep -E "*$user" /etc/group | gawk -F: '{ print $1 }')

		# Check if the user is apart of the docker group, if not then add the user to said group
		if ! echo "$groups" | grep -q "docker"; then
			sudo usermod -aG docker "$user"
			echo "[*] SUCCESS: $user has been added to the docker group"
		else
			echo "[*] INFO: $user is already apart of the docker group, skipping..."
		fi
	fi
	return $status
}

# Description: Installs zsh and Oh-My-ZSH
# Parameters: Current User
# Returns: 0 if zsh was successfully installed and 1 if not  
function install_zsh {
	local user=$1
	local status=
	echo -e "\n------------------------------"
	echo "--------Installing ZSH--------"
    echo "------------------------------"

	# Check if ZSH has been installed already
	if ! which zsh > /dev/null; then
		sudo apt update && sudo apt upgrade -y
		
		# If zsh is successfully installed, set status to 0 else set to 1
		if sudo apt install zsh; then
			echo "[*] SUCCESS: ZSH has been installed"
			status=0
		else
			echo "[*] ERROR: Unable to Install ZSH" > /dev/stderr
			status=1
		fi
	else
		echo "[*] INFO: ZSH is already installed, skipping install..."
		status=0
	fi

	# Change user shell to ZSH
	if ((status == 0)); then

		# See if ZSH is set as the users shell
		if ! grep "$user" /etc/passwd | gawk -F: '{ print $NF }' | grep -q "/bin/zsh"; then
			
			# Change the user shell to ZSH
			if sudo chsh -s /usr/bin/zsh "$user"; then
				echo "[*] SUCCESS: ZSH is now the $user's shell"
			else
				echo "[*] ERROR: Failed to make ZSH $user's shell" > /dev/stderr
			fi
		else
			echo "[*] INFO: $user's shell is already ZSH, skipping..."
		fi

		# Install Oh-My-ZSH
		if ! [[ -f /home/$user/.zshrc ]]; then
			wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh

			# Double check .zshrc file was added
			if ! [[ -f /home/$user/.zshrc ]]; then
				echo "[*] INFO: .zshrc file not added, adding from source"
				cp  /home/"$user"/.oh-my-zsh/templates/zshrc.zsh-template /home/"$user"/.zshrc
			fi
		else
			echo "[*] INFO: Oh-My-ZSH already installed, skipping..."
		fi
	fi
	return $status
} 


function customize_zsh {
	local user=$1
	echo -e "\n------------------------------"
	echo "-------Customizing  ZSH-------"
    echo "------------------------------"
	# If zsh-autosuggestions is not installed, install it
	if ! [[ -d /home/"$user"/.oh-my-zsh/plugins/zsh-autosuggestions ]]; then
		echo "[*] INFO: Installing ZSH-Autosuggestions"
		
		if git clone https://github.com/zsh-users/zsh-autosuggestions.git /home/"$user"/.oh-my-zsh/plugins/zsh-autosuggestions; then
			echo "[*] SUCCESS: ZSH-Autosuggestions successfully installed"
		else
			echo "[*] ERROR: ZSH-Autosuggestions failed to install" > /dev/stderr
		fi
	else
		echo "[*] INFO: ZSH-Autosuggestions is already installed, skipping..."	
	fi
	# If zsh-syntax-highlighting is not installed, install it
	if ! [[ -d /home/"$user"/.oh-my-zsh/plugins/zsh-syntax-highlighting ]]; then
		echo "[*] INFO: Installing ZSH-Syntax-Highlighting"
		
		if git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/"$user"/.oh-my-zsh/plugins/zsh-syntax-highlighting; then
			echo "[*]: SUCCESS: ZSH-Syntax-Highlighting successfully installed"
		else
			echo "[*]: ERROR: ZSH-Syntax-Highlighting failed to install" > /dev/stderr
		fi
	else
		echo "[*] INFO: ZSH-Autosuggestions is already installed, skipping..."
	fi


	# Move ZSH RC file and set permissions
	if ! grep -qi "kali" /home/"$user"/.zshrc; then
		echo "[*] INFO: Moving custom .zshrc"
		cp lumbago_zshrc /home/"$user"/.zshrc
		chmod 644 /home/"$user"/.zshrc
		chown "$user":"$user" /home/"$user"/.zshrc
		source /home/"$user"/.zshrc
	else
		echo "[*] INFO: Custom .zshrc already installed"
	fi
}

# Store the original username of the user who ran the script
user=$USER

# Update the system
sudo apt update && sudo apt upgrade -y

# Install VS Code
install_vscode

# Install Docker
install_docker "$user"

# Install ZSH
if install_zsh "$user"; then
		customize_zsh "$user"
fi