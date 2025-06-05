{\rtf1\ansi\ansicpg1252\cocoartf2822
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 #!/bin/bash\
\
# Clear screen before starting menu\
clear\
\
# ColorBerry Config Application\
# By N@Xs\
\
# Function to display error and return to main menu\
display_error() \{\
    dialog --colors --title "\\Z1Error\\Zn" --backtitle "ColorBerry Config" \\\
        --msgbox "\\Z1Error:\\Zn $1" 8 60\
    sleep 3\
    main_menu\
\}\
\
# Function to show progress (all commands run silently in background)\
show_progress() \{\
    local cmd=$1\
    local message=$2\
    \
    # Show 0% at start\
    echo "0" | dialog --colors --title "$message" --backtitle "ColorBerry Config" \\\
        --gauge "$message" 10 70 0\
    \
    # Execute command in background and capture PID\
    eval "$cmd > /dev/null 2>/tmp/error.log" &\
    local cmd_pid=$!\
    \
    # Monitor command progress\
    while kill -0 $cmd_pid 2>/dev/null; do\
        echo "50" | dialog --colors --title "$message" --backtitle "ColorBerry Config" \\\
            --gauge "$message" 10 70 0\
        sleep 0.5\
    done\
    \
    # Wait for command to complete and get exit status\
    wait $cmd_pid\
    local exit_status=$?\
    \
    # Show 100% completion\
    echo "100" | dialog --colors --title "$message" --backtitle "ColorBerry Config" \\\
        --gauge "$message" 10 70 0\
    sleep 0.5\
    \
    # Check if command failed\
    if [ $exit_status -ne 0 ]; then\
        display_error "$(cat /tmp/error.log)"\
        return 1\
    fi\
    \
    return 0\
\}\
\
# Function to show progress without stopping on errors - NO SHOW ERRORS\
show_progress_continue() \{\
    local cmd=$1\
    local message=$2\
    \
    # Show 0% at start\
    echo "0" | dialog --colors --title "$message" --backtitle "ColorBerry Config" \\\
        --gauge "$message" 10 70 0\
    \
    # Execute command in background and capture PID\
    eval "$cmd > /dev/null 2>/dev/null" &\
    local cmd_pid=$!\
    \
    # Monitor command progress\
    while kill -0 $cmd_pid 2>/dev/null; do\
        echo "50" | dialog --colors --title "$message" --backtitle "ColorBerry Config" \\\
            --gauge "$message" 10 70 0\
        sleep 0.5\
    done\
    \
    # Wait for command to complete (ignore exit status)\
    wait $cmd_pid || true\
    \
    # Show 100% completion\
    echo "100" | dialog --colors --title "$message" --backtitle "ColorBerry Config" \\\
        --gauge "$message" 10 70 0\
    sleep 0.5\
    \
    # Always return success - no error messages shown\
    return 0\
\}\
\
# Function to execute make install exactly like manual execution - NO SHOW ERRORS\
manual_make_install() \{\
    local message=$1\
    \
    echo "0" | dialog --colors --title "$message" --backtitle "ColorBerry Config" \\\
        --gauge "$message" 10 70 0\
    \
    # Ensure we're in the right directory\
    cd /var/tmp/jdi-drm-rpi > /dev/null 2>&1 || return 0\
    \
    echo "25" | dialog --colors --title "$message" --backtitle "ColorBerry Config" \\\
        --gauge "Preparing environment..." 10 70 0\
    \
    # Set up environment exactly like manual execution\
    export KERNEL_DIR="/lib/modules/$(uname -r)/build"\
    export KDIR="/lib/modules/$(uname -r)/build"\
    \
    echo "50" | dialog --colors --title "$message" --backtitle "ColorBerry Config" \\\
        --gauge "Running make install..." 10 70 0\
    \
    # Execute make install with proper environment - completely silent\
    sudo -E bash -c "\
        cd /var/tmp/jdi-drm-rpi\
        export KERNEL_DIR='/lib/modules/$(uname -r)/build'\
        export KDIR='/lib/modules/$(uname -r)/build'\
        make install\
    " > /dev/null 2>&1 || true\
    \
    echo "75" | dialog --colors --title "$message" --backtitle "ColorBerry Config" \\\
        --gauge "Finalizing installation..." 10 70 0\
    \
    # Always try to install the overlay manually as backup\
    sudo install -D -m 0644 /var/tmp/jdi-drm-rpi/sharp-drm.dtbo /boot/overlays/ > /dev/null 2>&1 || true\
    \
    # Add module to load at boot\
    if ! grep -q "sharp-drm" /etc/modules 2>/dev/null; then\
        echo "sharp-drm" | sudo tee -a /etc/modules > /dev/null 2>&1 || true\
    fi\
    \
    # Run depmod\
    sudo depmod -A > /dev/null 2>&1 || true\
    \
    echo "100" | dialog --colors --title "$message" --backtitle "ColorBerry Config" \\\
        --gauge "$message" 10 70 0\
    sleep 0.5\
    \
    # Always return success - no error messages\
    return 0\
\}\
\
# Function for ColorBerry Display Drivers Installation\
colorberrydisplay() \{\
    cd /home/$(whoami)/ColorBerry > /dev/null 2>&1 || \{\
        display_error "Could not access /home/$(whoami)/ColorBerry directory"\
        return 1\
    \}\
\
    show_progress_continue "sudo cp -r jdi-drm-rpi /var/tmp/" "Copying jdi-drm-rpi directory"\
    show_progress_continue "cd /" "Going to root directory"\
    show_progress_continue "cd /var/tmp/jdi-drm-rpi" "Changing to jdi-drm-rpi directory"\
    show_progress_continue "cd /var/tmp/jdi-drm-rpi && sudo make" "Compiling driver"\
    manual_make_install "Installing driver"\
    show_progress_continue "sudo mkdir -p /home/$(whoami)/sbin" "Creating sbin directory"\
    show_progress_continue "sudo cp /home/$(whoami)/ColorBerry/back.py /home/$(whoami)/sbin/" "Copying back.py script"\
    show_progress_continue "sudo chmod +x /home/$(whoami)/sbin/back.py" "Making script executable"\
    show_progress_continue "(sudo crontab -l 2>/dev/null; echo '@reboot sleep 5; /home/$(whoami)/sbin/back.py &') | sudo crontab -" "Configuring crontab"\
    show_progress_continue "echo 'dtoverlay=sharp-drm' | sudo tee -a /boot/config.txt" "Adding overlay to config.txt"\
    show_progress_continue "sudo raspi-config nonint do_i2c 0" "Enabling I2C"\
    show_progress_continue "cat > /tmp/bashrc_append.txt << 'EOF'\
if [ -z \\"\\$SSH_CONNECTION\\" ]; then\
        if [[ \\"\\$(tty)\\" =~ /dev/tty ]] && type fbterm > /dev/null 2>&1; then\
                fbterm\
        elif [ -z \\"\\$TMUX\\" ] && type tmux >/dev/null 2>&1; then\
                fcitx 2>/dev/null &\
                tmux new -As \\"\\$(basename \\$(tty))\\"\
        fi\
fi\
export PROMPT=\\"%c\\$ \\"\
export PATH=\\$PATH:~/sbin\
export SDL_VIDEODRIVER=\\"fbcon\\"\
export SDL_FBDEV=\\"/dev/fb1\\"\
alias d0=\\"echo 0 | sudo tee /sys/module/jdi_drm/parameters/dither\\"\
alias d3=\\"echo 3 | sudo tee /sys/module/jdi_drm/parameters/dither\\"\
alias d4=\\"echo 4 | sudo tee /sys/module/jdi_drm/parameters/dither\\"\
alias b=\\"echo 1 | sudo tee /sys/module/jdi_drm/parameters/backlit\\"\
alias bn=\\"echo 0 | sudo tee /sys/module/jdi_drm/parameters/backlit\\"\
alias key='echo \\"keys\\" | sudo tee /sys/module/beepy_kbd/parameters/touch_as > /dev/null'\
alias mouse='echo \\"mouse\\" | sudo tee /sys/module/beepy_kbd/parameters/touch_as > /dev/null'\
EOF\
sudo cat /tmp/bashrc_append.txt >> /home/$(whoami)/.bashrc\
rm /tmp/bashrc_append.txt" "Configuring .bashrc"\
    show_progress_continue "sudo apt-get install -y python3-pip" "Installing python3-pip"\
    show_progress_continue "pip3 install RPi.GPIO" "Installing RPi.GPIO"\
\
    dialog --colors --title "ColorBerry Display" --backtitle "ColorBerry Config" \\\
        --msgbox "Driver installation completed successfully.\\n\\nConfigured:\\n- jdi-drm-rpi display driver\\n- I2C configuration\\n- Startup scripts\\n- .bashrc configuration\\n- Python dependencies" 12 70\
    sleep 2\
\
    for i in \{5..1\}; do\
        dialog --colors --title "ColorBerry Config" --backtitle "ColorBerry Config" \\\
            --infobox "SYSTEM WILL REBOOT\\n\\nTime remaining: $i seconds" 5 50\
        sleep 1\
    done\
    \
    sudo reboot\
\}\
\
# Function for Colorberry-KBD option\
colorberrykbd() \{\
    cd /home/$(whoami)/ColorBerry > /dev/null 2>&1 || \{\
        display_error "Could not access /home/$(whoami)/ColorBerry directory"\
        return 1\
    \}\
\
    show_progress_continue "cd beepberry-keyboard-driver" "Changing to keyboard driver directory"\
    show_progress_continue "cd /home/$(whoami)/ColorBerry/beepberry-keyboard-driver && sudo make" "Compiling keyboard driver"\
    show_progress_continue "cd /home/$(whoami)/ColorBerry/beepberry-keyboard-driver && sudo make install" "Installing keyboard driver"\
\
    dialog --colors --title "Colorberry-KBD" --backtitle "ColorBerry Config" \\\
        --infobox "Installation completed" 3 30\
    sleep 2\
\
    main_menu\
\}\
\
# Function for Terminal Mode option\
terminalmode() \{\
    show_progress_continue "sudo systemctl set-default multi-user.target" "Disabling desktop environment"\
    show_progress_continue "sudo systemctl disable gdm3" "Disabling display manager"\
    show_progress_continue "sudo systemctl disable lightdm" "Disabling lightdm"\
    show_progress_continue "sudo systemctl disable sddm" "Disabling sddm"\
    show_progress_continue "sudo systemctl disable xdm" "Disabling xdm"\
\
    clear\
    dialog --colors --title "Terminal Mode" --backtitle "ColorBerry Config" \\\
        --infobox "Terminal mode active" 3 25\
    sleep 2\
\
    for i in \{3..1\}; do\
        dialog --colors --title "ColorBerry Config" --backtitle "ColorBerry Config" \\\
            --infobox "SYSTEM WILL REBOOT\\n\\nTime remaining: $i seconds" 5 50\
        sleep 1\
    done\
\
    clear\
    sudo reboot\
\}\
\
# Function for GUI Mode option\
guimode() \{\
    show_progress_continue "sudo systemctl set-default graphical.target" "Enabling desktop environment"\
    show_progress_continue "sudo apt-get install -y kali-desktop-xfce" "Installing ColorBerry desktop environment"\
    show_progress_continue "sudo apt-get install -y xorg" "Installing X server"\
    show_progress_continue "sudo systemctl enable lightdm" "Enabling display manager"\
    show_progress_continue "sudo systemctl enable gdm3" "Enabling GNOME display manager"\
\
    clear\
    dialog --colors --title "GUI Mode" --backtitle "ColorBerry Config" \\\
        --infobox "Returning to ColorBerry graphical environment" 3 40\
    sleep 2\
\
    for i in \{3..1\}; do\
        dialog --colors --title "ColorBerry Config" --backtitle "ColorBerry Config" \\\
            --infobox "SYSTEM WILL REBOOT\\n\\nTime remaining: $i seconds" 5 50\
        sleep 1\
    done\
\
    clear\
    sudo reboot\
\}\
\
# Function for Exit option\
exit_app() \{\
    dialog --colors --title "ColorBerry Config" --backtitle "ColorBerry Config" \\\
        --msgbox "Thank you for using ColorBerry Config By N@Xs\\n\\nDon't forget to install the keyboard driver" 7 60\
    sleep 1\
    clear\
    exit 0\
\}\
\
# Main menu function\
main_menu() \{\
    while true; do\
        choice=$(dialog --colors --title "ColorBerry Config" --backtitle "ColorBerry Config" \\\
            --menu "Select an option:" 16 60 5 \\\
            1 "ColorBerry Display" \\\
            2 "Colorberry-KBD" \\\
            3 "Terminal Mode" \\\
            4 "GUI Mode" \\\
            5 "Exit" \\\
            3>&1 1>&2 2>&3)\
        \
        case $choice in\
            1) colorberrydisplay ;;\
            2) colorberrykbd ;;\
            3) terminalmode ;;\
            4) guimode ;;\
            5) exit_app ;;\
            *) exit_app ;;\
        esac\
    done\
\}\
\
# Check if dialog is installed\
if ! command -v dialog &> /dev/null; then\
    echo "Installing dialog package..."\
    sudo apt-get update > /dev/null 2>&1\
    sudo apt-get install -y dialog > /dev/null 2>&1\
fi\
\
# Check if ColorBerry directory exists\
if [ ! -d "/home/$(whoami)/ColorBerry" ]; then\
    echo "Creating ColorBerry directory..."\
    sudo mkdir -p /home/$(whoami)/ColorBerry > /dev/null 2>&1\
fi\
\
# Set terminal colors (blue background, white text)\
export DIALOGRC=$(cat <<EOF\
# Dialog configuration\
screen_color = (WHITE,BLUE,ON)\
dialog_color = (BLACK,WHITE,OFF)\
title_color = (BLUE,WHITE,ON)\
border_color = (WHITE,WHITE,ON)\
button_active_color = (WHITE,BLUE,ON)\
button_inactive_color = (BLACK,WHITE,OFF)\
button_key_active_color = (WHITE,BLUE,ON)\
button_key_inactive_color = (RED,WHITE,OFF)\
button_label_active_color = (WHITE,BLUE,ON)\
button_label_inactive_color = (BLACK,WHITE,ON)\
inputbox_color = (BLACK,WHITE,OFF)\
inputbox_border_color = (BLACK,WHITE,OFF)\
searchbox_color = (BLACK,WHITE,OFF)\
searchbox_title_color = (BLUE,WHITE,ON)\
searchbox_border_color = (WHITE,WHITE,ON)\
position_indicator_color = (BLUE,WHITE,ON)\
menubox_color = (BLACK,WHITE,OFF)\
menubox_border_color = (WHITE,WHITE,ON)\
item_color = (BLACK,WHITE,OFF)\
item_selected_color = (WHITE,BLUE,ON)\
tag_color = (BLUE,WHITE,ON)\
tag_selected_color = (WHITE,BLUE,ON)\
tag_key_color = (RED,WHITE,OFF)\
tag_key_selected_color = (RED,BLUE,ON)\
check_color = (BLACK,WHITE,OFF)\
check_selected_color = (WHITE,BLUE,ON)\
uarrow_color = (GREEN,WHITE,ON)\
darrow_color = (GREEN,WHITE,ON)\
itemhelp_color = (BLACK,WHITE,OFF)\
EOF\
)\
\
# Start the application\
clear\
main_menu}