#!/bin/bash
# 
# Rends disponibles dans Munki les attributs
# 'hw_ssd_non_apple', 'hw_ssd_apple' et 'hw_ssd_internal' 
# pour une utilisation depuis les condtional_items
#
# Exemple 
# <key>condition</key>
# <string>hw_ssd_non_apple == 1</string>
# ou 
# <key>condition</key>
# <string>hw_ssd_internal == 1</string>
# ou
# <key>condition</key>
# <string>hw_ssd_apple == 1</string>

# Variables initialisation
version="munkiConditionsSSD v0.1 - 2016, Yvan Godard [godardyvan@gmail.com]"
versionOSX=$(sw_vers -productVersion)
scriptDir=$(dirname "${0}")
scriptName=$(basename "${0}")
scriptNameWithoutExt=$(echo "${scriptName}" | cut -f1 -d '.')

# Exécutable seulement par root
if [ `whoami` != 'root' ]
	then
	echo "Ce script doit être utilisé par le compte root. Utilisez 'sudo'."
	exit 1
fi

echo ""
echo "****************************** `date` ******************************"
echo "${scriptName} démarré..."
echo "sur Mac OSX version ${versionOSX}"
echo ""

# Changement du séparateur par défaut
OLDIFS=$IFS
IFS=$'\n'

# Récupération des valeurs
listOfDisks=$(diskutil list | grep "/dev/" | awk '{print $1}')
hasOneNonAppleSSD=0
hasOneAppleSSD=0
hasOneSSD=0
for disk in ${listOfDisks}
do
	echo "**************************************"
	echo "*** On traite le disque ${disk} ***"
	echo "**************************************"
	# On cherche si le disque est interne
	isInternalDisk=0
	isSSD=0
	isAPPLE=0
	[[ $(diskutil info ${disk} | awk '/Device Location/ { print $NF }') == "Internal" ]] && let isInternalDisk=${isInternalDisk}+1
	[[ $(diskutil info ${disk} | awk '/Internal:/ { print $NF }') == "Yes" ]] && let isInternalDisk=${isInternalDisk}+1
	if [[ ${isInternalDisk} -ne 0 ]]; then
		echo "Ce disque est un disque interne."
		diskutil info ${disk} | grep "Media Name" | grep "APPLE" > /dev/null 2>&1
		[ $? -eq 0 ] && let isAPPLE=${isAPPLE}+1
		[[ ${isAPPLE} -ne 0 ]] && echo "Ce disque est un disque original APPLE."
		[[ $(diskutil info ${disk} | grep "Solid State" | awk -F " " '{print $3}') == "Yes" ]] && isSSD=${isSSD}+1
		if [[ ${isSSD} -ne 0 ]]; then
			echo "Ce disque est un SSD."
			let hasOneSSD=${hasOneSSD}+1
			[[ ${isAPPLE} -ne 0 ]] && let hasOneAppleSSD=${hasOneAppleSSD}+1
			[[ ${isAPPLE} -eq 0 ]] && let hasOneNonAppleSSD=${hasOneNonAppleSSD}+1
		else
			echo "Ce disque n'est pas un SSD."
		fi
	elif [[ ${isInternalDisk} -eq 0 ]]; then
		echo "Ce disque n'est pas un disque interne."
		echo "On termine le test ici pour ce disque."
	fi
	echo ""
done

echo ""
echo "*** CONDITION hw_ssd_internal (cette machine contient au moins un disque interne SSD) : "
[[ ${hasOneSSD} -ne 0 ]] && echo ">>> Cet ordinateur possède un ou plusieurs disque(s) interne(s) SSD."
[[ ${hasOneSSD} -eq 0 ]] && echo ">>> Cet ordinateur ne possède pas de disque interne SSD."
echo ""
echo "*** CONDITION hw_ssd_non_apple (cette machine contient au moins un disque interne SSD non original APPLE) : "
[[ ${hasOneNonAppleSSD} -ne 0 ]] && echo ">>> Cet ordinateur possède un ou plusieurs disque(s) interne(s) SSD non originaux Apple."
[[ ${hasOneNonAppleSSD} -eq 0 ]] && echo ">>> Cet ordinateur ne possède pas de disque interne SSD non original Apple."
echo ""
echo "*** CONDITION hw_ssd_apple (cette machine contient au moins un disque interne SSD original APPLE) : "
[[ ${hasOneAppleSSD} -ne 0 ]] && echo ">>> Cet ordinateur possède un ou plusieurs disque(s) interne(s) SSD originaux Apple."
[[ ${hasOneAppleSSD} -eq 0 ]] && echo ">>> Cet ordinateur ne possède pas de disque interne SSD original Apple."

# liste des fichiers plist potentiels ManagedInstall.plist, séparés par % (MCX | /private/var/root/Library/Preferences/ManagedInstalls.plist | /Library/Preferences/ManagedInstalls.plist)
potentialPlists="/Library/Managed Preferences/ManagedInstalls.plist%/private/var/root/Library/Preferences/ManagedInstalls%/Library/Preferences/ManagedInstalls"

# Fichier temporaire contenant la liste des plist réels ManagedInstall.plist
listPlistsFiles=$(mktemp /tmp/list-plist-munki.XXXXX)

for plistFile in $(echo ${potentialPlists} | perl -p -e 's/%/\n/g' | awk '!x[$0]++')
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

		# On enregistre les valeurs 
		[[ ${hasOneSSD} -eq 0 ]] && sudo /usr/bin/defaults write "${plistLoc}" hw_ssd_internal -int 0
		[[ ${hasOneSSD} -ne 0 ]] && sudo /usr/bin/defaults write "${plistLoc}" hw_ssd_internal -int 1
		[[ ${hasOneNonAppleSSD} -eq 0 ]] && sudo /usr/bin/defaults write "${plistLoc}" hw_ssd_non_apple -int 0
		[[ ${hasOneNonAppleSSD} -ne 0 ]] && sudo /usr/bin/defaults write "${plistLoc}" hw_ssd_non_apple -int 1
		[[ ${hasOneAppleSSD} -eq 0 ]] && sudo /usr/bin/defaults write "${plistLoc}" hw_ssd_apple -int 0
		[[ ${hasOneAppleSSD} -ne 0 ]] && sudo /usr/bin/defaults write "${plistLoc}" hw_ssd_apple -int 1

		# Since 'defaults' outputs a binary plist, we should convert it back to XML
		/usr/bin/plutil -convert xml1 "${plistLoc}.plist"
		chmod 755 "${plistLoc}.plist"
	done
fi

[[ -e ${listPlistsFiles} ]] && rm ${listPlistsFiles}

IFS=$OLDIFS

exit 0