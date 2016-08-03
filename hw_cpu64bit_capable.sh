#!/bin/bash
# 
# Makes the value of /usr/sbin/sysctl -n hw.cpu64bit_capable
# available as 'hw_cpu64bit_capable' for use in condtional_items
#
# <key>condition</key>
# <string>hw_cpu64bit_capable == 1</string>

scriptDir=$(dirname "${0}")
scriptName=$(basename "${0}")

# Exécutable seulement par root
if [ `whoami` != 'root' ]
	then
	echo "Ce script doit être utilisé par le compte root. Utilisez 'sudo'."
	exit 1
fi

echo ""
echo "****************************** `date` ******************************"
echo "${scriptName} démarré..."
echo "sur Mac OSX version $(sw_vers -productVersion)"
echo ""

# Changement du séparateur par défaut
OLDIFS=$IFS
IFS=$'\n'

# Récupération de la valeur hw.cpu64bit_capable dans une variable
cpu64bitCapable=$(/usr/sbin/sysctl -n hw.cpu64bit_capable)
[[ ${cpu64bitCapable} -eq 1 ]] && echo "Votre matériel est compatible 64 bits."
[[ ${cpu64bitCapable} -ne 1 ]] && echo "Votre matériel est incompatible 64 bits."

# liste des fichiers plist potentiels ManagedInstall.plist, séparés par % (MCX | /private/var/root/Library/Preferences/ManagedInstalls.plist | /Library/Preferences/ManagedInstalls.plist)
potentialPlists="/Library/Managed Preferences/ManagedInstalls.plist%/private/var/root/Library/Preferences/ManagedInstalls%/Library/Preferences/ManagedInstalls"

# Fichier temporaire contenant la liste des plist réels ManagedInstall.plist
listPlistsFiles=$(mktemp /tmp/list-plist-munki.XXXXX)

for plistFile in $(echo ${potentialPlists} | perl -p -e 's/%/\n/g' | awk '!x[$0]++' )
do
	/usr/bin/defaults read ${plistFile} ManagedInstallDir > /dev/null 2>&1
	[ $? -eq 0 ] && managedInstallDir=$(/usr/bin/defaults read ${plistFile} ManagedInstallDir) && echo ${managedInstallDir} >> $listPlistsFiles
done

sort -u ${listPlistsFiles} > ${listPlistsFiles}.new
mv ${listPlistsFiles}.new ${listPlistsFiles}

nombrePlist=$(awk 'END {print NR}' ${listPlistsFiles})

if [[ -z $(cat ${listPlistsFiles}) ]] || [[ ${nombrePlist} -lt 1 ]]; then
	echo "" 
	echo "Aucun fichier de préférence de Munki trouvé. Nous quittons le processus."
	exit 1
else
	echo ""
	[[ ${nombrePlist} -eq 1 ]] && echo "Nous enregistrons cette information dans le fichier de préférences de Munki."
	[[ ${nombrePlist} -gt 1 ]] && echo "Nous enregistrons cette information dans les fichiers de préférences de Munki."
	echo ""
	[[ ${nombrePlist} -eq 1 ]] && echo "Le fichier ManagedInstall.plist est le suivant :"
	[[ ${nombrePlist} -gt 1 ]] && echo "Les fichiers ManagedInstall.plist sont les suivants :"

	for dirPlist in $(cat ${listPlistsFiles})
	do
		# Make sure we're outputting our information to "ConditionalItems.plist" 
		# (plist is left off since defaults requires this)
		plistLoc="${dirPlist}/ConditionalItems"

		echo " > ${plistLoc}.plist"

		# Note the key "hw_cpu64bit_capable" which becomes the condition that you would use in a predicate statement
		[[ ${cpu64bitCapable} -eq 1 ]] && sudo /usr/bin/defaults write "${plistLoc}" hw_cpu64bit_capable -int 1
		[[ ${cpu64bitCapable} -ne 1 ]] && sudo /usr/bin/defaults write "${plistLoc}" hw_cpu64bit_capable -int 0

		# Since 'defaults' outputs a binary plist, we should convert it back to XML
		/usr/bin/plutil -convert xml1 "${plistLoc}.plist"
		chmod 755 "${plistLoc}.plist"
	done
fi

[[ -e ${listPlistsFiles} ]] && rm ${listPlistsFiles}

IFS=$OLDIFS

exit 0