#!/bin/bash

# Variables initialisation
version="munkiConditionsCheckCompatibility v0.1 - 2016, Yvan Godard [godardyvan@gmail.com]"
versionOSX=$(sw_vers -productVersion | awk -F '.' '{print $(NF-1)}')
scriptDir=$(dirname "${0}")
scriptName=$(basename "${0}")
scriptNameWithoutExt=$(echo "${scriptName}" | cut -f1 -d '.')
scriptsDirCompatibilityCheck="/usr/local/scriptsDirCompatibilityCheck"
# Fichier temporaire contenant la liste des plist réels ManagedInstall.plist
listPlistsFiles=$(mktemp /tmp/scriptNameWithoutExt_plistList.XXXXX)
# Sous-script
scriptCheckMountainLionCompatibilityGit="https://raw.githubusercontent.com/hjuutilainen/adminscripts/master/check-mountainlion-compatibility.py"
scriptCheckMountainLionCompatibility="check-mountainlion-compatibility.py"
scriptCheckMavericksCompatibilityGit="https://raw.githubusercontent.com/hjuutilainen/adminscripts/master/check-mavericks-compatibility.py"
scriptCheckMavericksCompatibility="check-mavericks-compatibility.py"
scriptCheckYosemiteCompatibilityGit="https://raw.githubusercontent.com/hjuutilainen/adminscripts/master/check-yosemite-compatibility.py"
scriptCheckYosemiteCompatibility="check-yosemite-compatibility.py"
scriptCheckElCapitanCompatibilityGit="https://raw.githubusercontent.com/hjuutilainen/adminscripts/master/check-elcapitan-compatibility.py"
scriptCheckElCapitanCompatibility="check-elcapitan-compatibility.py"
# Default values
checkMountainLionCompatibility=0
checkMavericksCompatibility=0
checkYosemiteCompatibility=0
checkElCapitanCompatibility=0

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

# On installe les sous-scripts s'ils ne le sont pas 
echo "Téléchargement des scripts de tests :"
echo "- ${scriptCheckMountainLionCompatibility}"
[[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMountainLionCompatibility} ]] && rm ${scriptsDirCompatibilityCheck%/}/${scriptCheckMountainLionCompatibility}
curl --insecure ${scriptCheckMountainLionCompatibilityGit} -o ${scriptsDirCompatibilityCheck%/}/${scriptCheckMountainLionCompatibility}
chmod +x ${scriptsDirCompatibilityCheck%/}/${scriptCheckMountainLionCompatibility}
echo "- ${scriptCheckMavericksCompatibility}"
[[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMavericksCompatibility} ]] && rm ${scriptsDirCompatibilityCheck%/}/${scriptCheckMavericksCompatibility}
curl --insecure ${scriptCheckMavericksCompatibilityGit} -o ${scriptsDirCompatibilityCheck%/}/${scriptCheckMavericksCompatibility}
chmod +x ${scriptsDirCompatibilityCheck%/}/${scriptCheckMavericksCompatibility}
echo "- ${scriptCheckYosemiteCompatibility}"
[[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckYosemiteCompatibility} ]] && rm ${scriptsDirCompatibilityCheck%/}/${scriptCheckYosemiteCompatibility}
curl --insecure ${scriptCheckYosemiteCompatibilityGit} -o ${scriptsDirCompatibilityCheck%/}/${scriptCheckYosemiteCompatibility}
chmod +x ${scriptsDirCompatibilityCheck%/}/${scriptCheckYosemiteCompatibility}
echo "- ${scriptCheckElCapitanCompatibility}"
[[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckElCapitanCompatibility} ]] && rm ${scriptsDirCompatibilityCheck%/}/${scriptCheckElCapitanCompatibility}
curl --insecure ${scriptCheckElCapitanCompatibilityGit} -o ${scriptsDirCompatibilityCheck%/}/${scriptCheckElCapitanCompatibility}
chmod +x ${scriptsDirCompatibilityCheck%/}/${scriptCheckElCapitanCompatibility}
echo ""

# liste des fichiers plist potentiels ManagedInstall.plist, séparés par % (MCX | /private/var/root/Library/Preferences/ManagedInstalls.plist | /Library/Preferences/ManagedInstalls.plist)
potentialPlistsList="/Library/Managed Preferences/ManagedInstalls.plist%/private/var/root/Library/Preferences/ManagedInstalls%/Library/Preferences/ManagedInstalls"

# Changement du séparateur par défaut
OLDIFS=$IFS
IFS=$'\n'

# Lancement des sous-scripts
if [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMountainLionCompatibility} ]] || [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMavericksCompatibility} ]] || [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckYosemiteCompatibility} ]] || [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckElCapitanCompatibility} ]]; then
	echo "Compatibilité OS :"
	if [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMountainLionCompatibility} ]]; then
		${scriptsDirCompatibilityCheck%/}/${scriptCheckMountainLionCompatibility} > /dev/null 2>&1
		[[ $? -eq 0 ]] && checkMountainLionCompatibility=1
		echo "- check-mountainlion-compatibility : ${checkMountainLionCompatibility}"
		for line in $(${scriptsDirCompatibilityCheck%/}/${scriptCheckMountainLionCompatibility} | tr -s ' '); do echo "		${line}"; done
	fi
	if [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckMavericksCompatibility} ]]; then
		${scriptsDirCompatibilityCheck%/}/${scriptCheckMavericksCompatibility} > /dev/null 2>&1
		[[ $? -eq 0 ]] && checkMavericksCompatibility=1
		echo "- check-mavericks-compatibility : ${checkMavericksCompatibility}"
		for line in $(${scriptsDirCompatibilityCheck%/}/${scriptCheckMavericksCompatibility} | tr -s ' '); do echo "		${line}"; done
	fi
	if [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckYosemiteCompatibility} ]]; then
		${scriptsDirCompatibilityCheck%/}/${scriptCheckYosemiteCompatibility} > /dev/null 2>&1
		[[ $? -eq 0 ]] && checkYosemiteCompatibility=1
		echo "- check-yosemite-compatibility : ${checkYosemiteCompatibility}"
		for line in $(${scriptsDirCompatibilityCheck%/}/${scriptCheckYosemiteCompatibility} | tr -s ' '); do echo "		${line}"; done
	fi
	if [[ -e ${scriptsDirCompatibilityCheck%/}/${scriptCheckElCapitanCompatibility} ]]; then
		${scriptsDirCompatibilityCheck%/}/${scriptCheckElCapitanCompatibility} > /dev/null 2>&1
		[[ $? -eq 0 ]] && checkElCapitanCompatibility=1
		echo "- check-elcapitan-compatibility : ${checkElCapitanCompatibility}"
		for line in $(${scriptsDirCompatibilityCheck%/}/${scriptCheckElCapitanCompatibility} | tr -s ' '); do echo "		${line}"; done
	fi

	for plistFile in $(echo ${potentialPlistsList} | perl -p -e 's/%/\n/g' | awk '!x[$0]++')
	do
		/usr/bin/defaults read ${plistFile} ManagedInstallDir > /dev/null 2>&1
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

			# Since 'defaults' outputs a binary plist, we should convert it back to XML
			/usr/bin/plutil -convert xml1 "${plistLoc}.plist"
			chmod 755 "${plistLoc}.plist"
		done
	fi
fi

[[ -e ${listPlistsFiles} ]] && rm ${listPlistsFiles}

IFS=$OLDIFS

exit 0