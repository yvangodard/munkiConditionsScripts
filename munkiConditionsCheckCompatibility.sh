#!/bin/bash

# Variables initialisation
version="munkiConditionsCheckCompatibility v0.2 - 2016, Yvan Godard [godardyvan@gmail.com]"
versionOSX=$(sw_vers -productVersion | awk -F '.' '{print $(NF-1)}')
scriptDir=$(dirname "${0}")
scriptName=$(basename "${0}")
scriptNameWithoutExt=$(echo "${scriptName}" | cut -f1 -d '.')
scriptsDirCompatibilityCheck="/usr/local/scriptsDirCompatibilityCheck"
# Fichier temporaire contenant la liste des plist réels ManagedInstall.plist
listPlistsFiles=$(mktemp /tmp/scriptNameWithoutExt_plistList.XXXXX)
# Sous-script
scriptCheckMacOS10_8CompatibilityGit="https://raw.githubusercontent.com/hjuutilainen/adminscripts/master/check-10.8-mountainlion-compatibility.py"
scriptCheckMacOS10_8Compatibility="check-10.8-mountainlion-compatibility.py"
scriptCheckMacOS10_9CompatibilityGit="https://raw.githubusercontent.com/hjuutilainen/adminscripts/master/check-10.9-mavericks-compatibility.py"
scriptCheckMacOS10_9Compatibility="check-10.9-mavericks-compatibility.py"
scriptCheckMacOS10_10CompatibilityGit="https://raw.githubusercontent.com/hjuutilainen/adminscripts/master/check-10.10-yosemite-compatibility.py"
scriptCheckMacOS10_10Compatibility="check-10.10-yosemite-compatibility.py"
scriptCheckMacOS10_11CompatibilityGit="https://raw.githubusercontent.com/hjuutilainen/adminscripts/master/check-10.11-elcapitan-compatibility.py"
scriptCheckMacOS10_11Compatibility="check-10.11-elcapitan-compatibility.py"
scriptCheckMacOS10_12CompatibilityGit="https://raw.githubusercontent.com/hjuutilainen/adminscripts/master/check-10.12-sierra-compatibility.py"
scriptCheckMacOS10_12Compatibility="check-10.12-sierra-compatibility.py"
# Default values
checkMountainLionCompatibility=0
checkMavericksCompatibility=0
checkYosemiteCompatibility=0
checkElCapitanCompatibility=0
checkSierraCompatibility=0

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

# Test connecté à internet
dig +short myip.opendns.com @resolver1.opendns.com > /dev/null 2>&1
[[ $? -ne 0 ]] && echo "Non connecté à internet. Cet outil nécessite une connection pour fonctionner !" && exit 1

# On teste les dossiers
if [[ ! -e ${scriptsDirCompatibilityCheck} ]]; then
	echo "On créé le dossier ${scriptsDirCompatibilityCheck} pour y installer les scripts de test de compatibilité."
	echo ""
	mkdir -p ${scriptsDirCompatibilityCheck}
	[[ $? -ne 0 ]] && echo "Impossible de créer le dossier ${scriptsDirCompatibilityCheck}. Nous quittons." && exit 1
fi

# Suppression des anciennes versions de check scripts
[[ -e ${scriptsDirCompatibilityCheck%/}/check-mountainlion-compatibility.py ]] && rm ${scriptsDirCompatibilityCheck%/}/check-mountainlion-compatibility.py
[[ -e ${scriptsDirCompatibilityCheck%/}/check-mavericks-compatibility.py ]] && rm ${scriptsDirCompatibilityCheck%/}/check-mavericks-compatibility.py
[[ -e ${scriptsDirCompatibilityCheck%/}/check-yosemite-compatibility.py ]] && rm ${scriptsDirCompatibilityCheck%/}/check-yosemite-compatibility.py
[[ -e ${scriptsDirCompatibilityCheck%/}/check-elcapitan-compatibility.py ]] && rm ${scriptsDirCompatibilityCheck%/}/check-elcapitan-compatibility.py

# On installe les sous-scripts s'ils ne le sont pas 
echo "Téléchargement des scripts de tests :"
echo "- ${scriptCheckMacOS10_8Compatibility}"
[[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_8Compatibility} ]] && rm ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_8Compatibility}
curl --insecure ${scriptCheckMacOS10_8CompatibilityGit} -o ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_8Compatibility}
chmod +x ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_8Compatibility}
echo "- ${scriptCheckMacOS10_9Compatibility}"
[[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_9Compatibility} ]] && rm ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_9Compatibility}
curl --insecure ${scriptCheckMacOS10_9CompatibilityGit} -o ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_9Compatibility}
chmod +x ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_9Compatibility}
echo "- ${scriptCheckMacOS10_10Compatibility}"
[[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_10Compatibility} ]] && rm ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_10Compatibility}
curl --insecure ${scriptCheckMacOS10_10CompatibilityGit} -o ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_10Compatibility}
chmod +x ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_10Compatibility}
echo "- ${scriptCheckMacOS10_11Compatibility}"
[[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_11Compatibility} ]] && rm ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_11Compatibility}
curl --insecure ${scriptCheckMacOS10_11CompatibilityGit} -o ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_11Compatibility}
chmod +x ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_11Compatibility}
echo "- ${scriptCheckMacOS10_12Compatibility}"
[[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_12Compatibility} ]] && rm ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_12Compatibility}
curl --insecure ${scriptCheckMacOS10_12CompatibilityGit} -o ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_12Compatibility}
chmod +x ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_12Compatibility}
echo ""

# liste des fichiers plist potentiels ManagedInstall.plist, séparés par % (MCX | /private/var/root/Library/Preferences/ManagedInstalls.plist | /Library/Preferences/ManagedInstalls.plist)
potentialPlistsList="/Library/Managed Preferences/ManagedInstalls.plist%/private/var/root/Library/Preferences/ManagedInstalls%/Library/Preferences/ManagedInstalls"

# Changement du séparateur par défaut
OLDIFS=$IFS
IFS=$'\n'

# Lancement des sous-scripts
if [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_8Compatibility} ]] || [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_9Compatibility} ]] || [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_10Compatibility} ]] || [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_11Compatibility} ]]; then
	echo "Compatibilité OS :"
	if [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_8Compatibility} ]]; then
		${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_8Compatibility} > /dev/null 2>&1
		[[ $? -eq 0 ]] && checkMountainLionCompatibility=1
		echo "- check-mountainlion-compatibility : ${checkMountainLionCompatibility}"
		for line in $(${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_8Compatibility} | tr -s ' '); do echo "		${line}"; done
	fi
	if [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_9Compatibility} ]]; then
		${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_9Compatibility} > /dev/null 2>&1
		[[ $? -eq 0 ]] && checkMavericksCompatibility=1
		echo "- check-mavericks-compatibility : ${checkMavericksCompatibility}"
		for line in $(${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_9Compatibility} | tr -s ' '); do echo "		${line}"; done
	fi
	if [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_10Compatibility} ]]; then
		${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_10Compatibility} > /dev/null 2>&1
		[[ $? -eq 0 ]] && checkYosemiteCompatibility=1
		echo "- check-yosemite-compatibility : ${checkYosemiteCompatibility}"
		for line in $(${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_10Compatibility} | tr -s ' '); do echo "		${line}"; done
	fi
	if [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_11Compatibility} ]]; then
		${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_11Compatibility} > /dev/null 2>&1
		[[ $? -eq 0 ]] && checkElCapitanCompatibility=1
		echo "- check-elcapitan-compatibility : ${checkElCapitanCompatibility}"
		for line in $(${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_11Compatibility} | tr -s ' '); do echo "		${line}"; done
	fi
	if [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_12Compatibility} ]]; then
		${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_12Compatibility} > /dev/null 2>&1
		[[ $? -eq 0 ]] && checkSierraCompatibility=1
		echo "- check-sierra-compatibility : ${checkSierraCompatibility}"
		for line in $(${scriptsDirCompatibilityCheck%/}/${scriptCheckMacOS10_12Compatibility} | tr -s ' '); do echo "		${line}"; done
	fi

	for plistFile in $(echo ${potentialPlistsList} | perl -p -e 's/%/\n/g' | awk '!x[$0]++')
	do
		/usr/bin/defaults read "${plistFile}" ManagedInstallDir > /dev/null 2>&1
		[[ $? -eq 0 ]] && managedInstallDir=$(/usr/bin/defaults read ${plistFile} ManagedInstallDir) && echo "${managedInstallDir}" >> ${listPlistsFiles}
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
		[[ ${nombrePlist} -eq 1 ]] && echo "Nous enregistrons ces informations dans le fichier de préférences de Munki."
		[[ ${nombrePlist} -gt 1 ]] && echo "Nous enregistrons ces informations dans les fichiers de préférences de Munki."
		echo ""
		[[ ${nombrePlist} -eq 1 ]] && echo "Le fichier ManagedInstall.plist est le suivant :"
		[[ ${nombrePlist} -gt 1 ]] && echo "Les fichiers ManagedInstall.plist sont les suivants :"
		for dirPlist in $(cat ${listPlistsFiles})
		do
			# Make sure we're outputting our information to "ConditionalItems.plist" 
			# (plist is left off since defaults requires this)
			plistLoc="${dirPlist%/}/ConditionalItems"

			echo "- ${plistLoc}.plist"

			# On enregistre les valeurs
			# MountainLion
			[[ ${checkMountainLionCompatibility} -eq 1 ]] && sudo /usr/bin/defaults write "${plistLoc}" osx_mountainlion_compatibility -int 1
			[[ ${checkMountainLionCompatibility} -ne 1 ]] && sudo /usr/bin/defaults write "${plistLoc}" osx_mountainlion_compatibility -int 0
			# Mavericks
			[[ ${checkMavericksCompatibility} -eq 1 ]] && sudo /usr/bin/defaults write "${plistLoc}" osx_mavericks_compatibility -int 1
			[[ ${checkMavericksCompatibility} -ne 1 ]] && sudo /usr/bin/defaults write "${plistLoc}" osx_mavericks_compatibility -int 0
			# Yosemite
			[[ ${checkYosemiteCompatibility} -eq 1 ]] && sudo /usr/bin/defaults write "${plistLoc}" osx_yosemite_compatibility -int 1
			[[ ${checkYosemiteCompatibility} -ne 1 ]] && sudo /usr/bin/defaults write "${plistLoc}" osx_yosemite_compatibility -int 0
			# El Capitan
			[[ ${checkElCapitanCompatibility} -eq 1 ]] && sudo /usr/bin/defaults write "${plistLoc}" osx_elcapitan_compatibility -int 1
			[[ ${checkElCapitanCompatibility} -ne 1 ]] && sudo /usr/bin/defaults write "${plistLoc}" osx_elcapitan_compatibility -int 0
			# Sierra
			[[ ${checkSierraCompatibility} -eq 1 ]] && sudo /usr/bin/defaults write "${plistLoc}" osx_sierra_compatibility -int 1
			[[ ${checkSierraCompatibility} -ne 1 ]] && sudo /usr/bin/defaults write "${plistLoc}" osx_sierra_compatibility -int 0
			# Since 'defaults' outputs a binary plist, we should convert it back to XML
			/usr/bin/plutil -convert xml1 "${plistLoc}.plist"
			chmod 755 "${plistLoc}.plist"
		done
	fi
fi

[[ -e ${listPlistsFiles} ]] && rm ${listPlistsFiles}

IFS=$OLDIFS

exit 0