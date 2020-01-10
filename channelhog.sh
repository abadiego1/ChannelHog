#!/bin/sh
############################################################################################################
#                                                                                                          #
#           ██████╗██╗  ██╗ █████╗ ███╗   ██╗███╗   ██╗███████╗██╗     ██╗  ██╗ ██████╗  ██████╗           #
#          ██╔════╝██║  ██║██╔══██╗████╗  ██║████╗  ██║██╔════╝██║     ██║  ██║██╔═══██╗██╔════╝           #
#          ██║     ███████║███████║██╔██╗ ██║██╔██╗ ██║█████╗  ██║     ███████║██║   ██║██║  ███╗          #
#          ██║     ██╔══██║██╔══██║██║╚██╗██║██║╚██╗██║██╔══╝  ██║     ██╔══██║██║   ██║██║   ██║          #
#          ╚██████╗██║  ██║██║  ██║██║ ╚████║██║ ╚████║███████╗███████╗██║  ██║╚██████╔╝╚██████╔╝          #
#           ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝           #
#                                                                                                          #
#                          Monitor And Force Maximum 5GHz Bandwidth For Asus Routers                       #
#                                  By Adamm - https://github.com/Adamm00                                   #
#                                           11/01/2019 - v1.0.0                                            #
############################################################################################################



botname="ChannelHogBOT"
avatar="https://i.imgur.com/jZk12SL.png"
channelhogcfg="/jffs/addons/channelhog/channelhog.cfg"

clear
sed -n '2,16p' "$0"
port5ghz="$(ifconfig | grep -F "$(nvram get wl1_hwaddr)" | awk '{print $1}')"

Kill_Lock () {
		if [ -f "/tmp/channelhog.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/channelhog.lock)" ]; then
			logger -st ChannelHog "[*] Killing Locked Processes ($(sed -n '1p' /tmp/channelhog.lock)) (pid=$(sed -n '2p' /tmp/channelhog.lock))"
			logger -st ChannelHog "[*] $(ps | awk -v pid="$(sed -n '2p' /tmp/channelhog.lock)" '$1 == pid')"
			kill "$(sed -n '2p' /tmp/channelhog.lock)"
			rm -rf /tmp/channelhog.lock
			echo
		fi
}

Check_Lock () {
		if [ -f "/tmp/channelhog.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/channelhog.lock)" ] && [ "$(sed -n '2p' /tmp/channelhog.lock)" != "$$" ]; then
			if [ "$(($(date +%s)-$(sed -n '3p' /tmp/channelhog.lock)))" -gt "1800" ]; then
				Kill_Lock
			else
				logger -st ChannelHog "[*] Lock File Detected ($(sed -n '1p' /tmp/channelhog.lock)) (pid=$(sed -n '2p' /tmp/channelhog.lock)) - Exiting (cpid=$$)"
				echo; exit 1
			fi
		fi
		echo "$@" > /tmp/channelhog.lock
		echo "$$" >> /tmp/channelhog.lock
		date +%s >> /tmp/channelhog.lock
		lockchannelhog="true"
}

Load_Cron () {
	cru a ChannelHog "45 4 * * * sh /jffs/addons/channelhog/channelhog.sh check"
}

Unload_Cron () {
	cru d ChannelHog
}

Write_Config () {
		{ printf "%s\\n" "####################################################"
		printf "%s\\n" "## Generated By ChannelHog - Do Not Manually Edit ##"
		printf "%-49s %s\\n\\n" "## $(date +"%b %d %T")" "##"
		printf "%s\\n" "## Installer ##"
		printf "%s=\"%s\"\\n" "enablediscord" "$enablediscord"
		printf "%s=\"%s\"\\n" "webhookurl" "$webhookurl"
		printf "\\n%s\\n" "####################################################"; } > "$channelhogcfg"
}

Filter_Version () {
		grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})'
}


Load_Menu () {
	while true; do
		echo "Select Menu Option:"
		echo "[1]  --> Start ChannelHog"
		echo "[2]  --> Check Channel Bandwidth"
		echo "[3]  --> Temporarily Disable ChannelHog"
		echo "[4]  --> Update ChannelHog"
		echo "[5]  --> Install ChannelHog"
		echo "[6]  --> Uninstall"
		echo
		echo "[e]  --> Exit Menu"
		echo
		printf "[1-6]: "
		read -r "menu"
		echo
		case "$menu" in
			1)
				option1="start"
				break
			;;
			2)
				option1="check"
				break
			;;
			3)
				option1="disable"
				break
			;;
			4)
				option1="update"
				break
			;;
			5)
				option1="install"
				break
			;;
			6)
				option1="uninstall"
				break
			;;
			e|exit)
				echo "[*] Exiting!"
				echo; exit 0
			;;
			*)
				echo "[*] $menu Isn't An Option!"
				echo
			;;
		esac
	done
}

if [ -z "$1" ]; then
	Load_Menu
fi

if [ -n "$option1" ]; then
	set "$option1"
fi

case "$1" in
	start)
		Check_Lock "$@"
		Unload_Cron
		Load_Cron
	;;

	check)
		Check_Lock "$@"
		. "$channelhogcfg"
		currentbandwidth="$(wl -i "$port5ghz" assoc | grep -F "Chanspec" | awk '{print $5}')"
		targetbandwidth="160MHz"
		if [ "$currentbandwidth" != "$targetbandwidth" ]; then
			if [ "$enablediscord" = "true" ]; then
				curl -s -H "Content-Type: application/json" \
				-X POST \
				-d "$(cat <<EOF
				{
					"username": "$botname",
					"avatar_url": "$avatar",
					"content": "Channel Width Error Detected - Restarting 5GHz Radio @everyone",
					"embeds": [{
						"title": "$(nvram get model)",
						"color": 15749200,
						"url": "https://$(nvram get lan_ipaddr):$(nvram get https_lanport)",
						"fields": [{
								"name": "Current Channel Width",
								"value": "$currentbandwidth",
								"inline": true
							},
							{
								"name": "Target Channel Width",
								"value": "$targetbandwidth",
								"inline": true
							},
							{
								"name": "Uptime",
								"value": "$(uptime | awk -F'( |,|:)+' '{if ($7=="min") m=$6; else {if ($7~/^day/) {d=$6;h=$8;m=$9} else {h=$6;m=$7}}} {print d+0,"days,",h+0,"hours,",m+0,"minutes."}')",
								"inline": false
							}
						],
						"footer": {
							"text": "$(date)",
							"icon_url": "$avatar"
						}
					}]
				}
EOF
							)" "$webhookurl"
			fi
			logger -st ChannelHog "$currentbandwidth Channel Width Detected - Restarting 5GHz Radio"
			wl -i "$port5ghz" down
			wl -i "$port5ghz" up
		else
			echo "[i] $currentbandwidth Channel Width Detected - No Action Required"
		fi
	;;

	disable)
		Check_Lock "$@"
		Unload_Cron
		echo "[%] ChannelHog Disabled"
	;;

	update)
		Check_Lock "$@"
		remoteurl="https://raw.githubusercontent.com/Adamm00/ChannelHog/master/channelhog.sh"
		curl -fsL --retry 3 "$remoteurl" | grep -qF "Adamm" || { logger -st ChannelHog "[*] 404 Error Detected - Stopping Update"; echo; exit 1; }
		localver="$(Filter_Version < "$0")"
		remotever="$(curl -fsL --retry 3 "$remoteurl" | Filter_Version)"
		localmd5="$(md5sum "$0" | awk '{print $1}')"
		remotemd5="$(curl -fsL --retry 3 "$remoteurl" | md5sum | awk '{print $1}')"
		if [ "$localmd5" = "$remotemd5" ] && [ "$2" != "-f" ]; then
			logger -t ChannelHog "[%] ChannelHog Up To Date - $localver (${localmd5})"; echo "[%] ChannelHog Up To Date - $localver (${localmd5})"
		elif [ "$localmd5" != "$remotemd5" ] && [ "$2" = "check" ]; then
			logger -t ChannelHog "[%] ChannelHog Update Detected - $remotever (${remotemd5})"; echo "[%] ChannelHog Update Detected - $remotever (${remotemd5})"
			nolog="2"
		elif [ "$2" = "-f" ]; then
			echo "[i] Forcing Update"
		fi
		if [ "$localmd5" != "$remotemd5" ] || [ "$2" = "-f" ] && [ "$nolog" != "2" ]; then
			logger -t ChannelHog "[%] New Version Detected - Updating To $remotever (${remotemd5})"; echo "[%] New Version Detected - Updating To $remotever (${remotemd5})"
			curl -fsL --retry 3 "$remoteurl" -o "$0" || { logger -st ChannelHog "[*] Update Failed - Exiting"; echo; exit 1; }
			echo; exit 0
		fi
	;;

	install)
		[ -z "$(nvram get odmpid)" ] && model="$(nvram get productid)" || model="$(nvram get odmpid)"
		if [ "$model" = "RT-AX88U" ]; then
			Check_Lock "$@"
			while true; do
				echo "Would You Like To Enable Discord Notifications?"
				echo "[1]  --> Yes"
				echo "[2]  --> No"
				echo
				echo "[e]  --> Exit Menu"
				echo
				echo "Please Select Option"
				printf "[1-2]: "
				read -r "menu1"
				echo
				case "$menu1" in
					1)
						while true; do
							echo "Please Enter Discord Channel Webhook URL"
							printf "[URL]: "
							read -r "webhookurl"
							echo
							if [ "$webhookurl" = "e" ]; then
								echo "[*] Exiting!"
								echo; exit 0
							fi
							if ! curl -sI "$webhookurl" | grep -qE "HTTP/1.[01] [23].." || ! curl -s "$webhookurl" | grep -qF "token"; then
								echo "[*] $webhookurl Isn't A Valid URL!"
								echo
								continue
							fi
							enablediscord="true"
							break
						done
						break
					;;
					2)
						echo "[i] Discord Notifications Disabled"
						enablediscord="false"
						break
					;;
					e|exit)
						echo "[*] Exiting!"
						echo; exit 0
					;;
					*)
						echo "[*] $menu1 Isn't An Option!"
						echo
					;;
				esac
			done
			if [ ! -f "/jffs/scripts/init-start" ]; then
				echo "#!/bin/sh" > /jffs/scripts/init-start
				echo >> /jffs/scripts/init-start
			elif [ -f "/jffs/scripts/init-start" ] && ! head -1 /jffs/scripts/init-start | grep -qE "^#!/bin/sh"; then
				sed -i '1s~^~#!/bin/sh\n~' /jffs/scripts/init-start
			fi
			cmdline="sh /jffs/addons/channelhog/channelhog.sh start # ChannelHog"
			if grep -qE "^$cmdline" /jffs/scripts/init-start; then
				sed -i "s~^sh /jffs/addons/channelhog/channelhog.sh .* # ChannelHog~$cmdline~" /jffs/scripts/init-start
			else
				echo "$cmdline" >> /jffs/scripts/init-start
			fi
			chmod 755 "/jffs/scripts/init-start" "/jffs/addons/channelhog/channelhog.sh"
			if [ -d "/opt/bin" ] && [ ! -L "/opt/bin/channelhog" ]; then
				ln -s /jffs/addons/channelhog/channelhog.sh /opt/bin/channelhog
			fi
			Unload_Cron
			Load_Cron
			Write_Config
			if [ "$(nvram get wl1_bw)" != "5" ]; then
				nvram set wl1_bw=5
				echo "[i] Restarting 5GHz Radio To Complete Installation"
				printf "[i] Press Enter To Continue..."; read -r "continue"
				wl -i "$port5ghz" down
				wl -i "$port5ghz" up
			fi
		else
			echo "[*] ChannelHog currently only supports the RT-AX88U"
		fi
	;;

	uninstall)
		Check_Lock "$@"
		echo "If You Were Experiencing Issues, Try Update Or Visit SNBForums/Github For Support"
		echo "https://github.com/Adamm00/IPSet_ASUS"
		echo
		while true; do
			echo "[!] Warning - This Will Delete All ChannelHog Related Files"
			echo "Are You Sure You Want To Uninstall?"
			echo
			echo "[1]  --> Yes"
			echo "[2]  --> No"
			echo
			echo "Please Select Option"
			printf "[1-2]: "
			read -r "continue"
			echo
			case "$continue" in
				1)
					echo "[i] Deleting ChannelHog Files"
					echo
					sed -i '\~# ChannelHog~d' /jffs/scripts/init-start
					rm -rf "/jffs/addons/channelhog" "/opt/bin/channelhog"
					exit 0
				;;
				2|e|exit)
					echo "[*] Exiting!"
					echo; exit 0
				;;
				*)
					echo "[*] $continue Isn't An Option!"
					echo
				;;
			esac
		done
	;;
	*)
		echo "Command Not Recognized, Please Try Again"
		echo "Accepted Commands Are; (sh $0 [start|check|disable|install|uninstall])"
		echo; exit 2
	;;
esac
if [ "$lockchannelhog" = "true" ]; then rm -rf "/tmp/channelhog.lock"; fi
echo