#!/bin/bash

# File
TIMESTAMP="$(date '+%H:%M:%S-%d_%m_%Y')"
FILENAME="spells.${TIMESTAMP}.json"

# Aidedd Endpoint
ENDPOINT="https://www.aidedd.org/dnd-filters/sorts.php"

# Function to write on the json filename
function filePrintf() {
    # shellcheck disable=SC2059
    printf "${@}" >> "${FILENAME}"
}

CLOCK=("🕛" "🕐" "🕑" "🕒" "🕓" "🕔" "🕕" "🕖" "🕗" "🕘" "🕙" "🕚")
CLOCK_LENGHT="${#CLOCK[@]}"

######################
## Script Beginning ##
######################

printf "🪛 AideDD Web Scrapper\n"
printf "📚 Getting Spells at address \"%s\"\n\n" "${ENDPOINT}"

# Init file and erase it's content if it exists
printf "" > "${FILENAME}"

# Get base DOM from the Endpoint
INITIAL_TABLE=$(curl "${ENDPOINT}" 2> /dev/null)

# Get all spell's URLs
URL_TABLE=$(echo "${INITIAL_TABLE}" | \
    grep -zo "https://www.aidedd.org/dnd/sorts.php?[^\"]*\"" | \
    tr -d '\0' | \
    sed 's/"/\n/g')

# Create array from URLs
readarray -td$'\n' URL_ARRAY <<< "${URL_TABLE}"
declare -p URL_ARRAY > /dev/null

# Begin JSON list
filePrintf "["

INDEX="1"
LENGHT="${#URL_ARRAY[@]}"

# Loop on Spells
for SPELL_URL in "${URL_ARRAY[@]}"; do
    printf "%s - %s%% Progress: %s/%s" "${CLOCK[$((INDEX%CLOCK_LENGHT))]}" "$((INDEX*100/LENGHT))" "$((INDEX++))" "${LENGHT}"

    # Create object on JSON
    filePrintf "{"

    filePrintf "\"url\":\"%s\"," "${SPELL_URL}"

    # Get content of Spell
    CURRENT_SPELL=$(curl "${SPELL_URL}" 2> /dev/null | grep "${SPELL_URL}")

    # Get Name
    NAME=$(echo "$CURRENT_SPELL}" | \
        grep -o "<h1>[^<]*</h1>" | \
        sed "s/<[^>]*>//g" )
    filePrintf "\"name\":\"%s\"," "${NAME}"

    # Get Rank
    RANK=$(echo "${CURRENT_SPELL}" | \
        grep -o "<div class=\"ecole\">[^<]*</div>" | \
        sed "s/<[^>]*>//g" )

    # Get Level
    LEVEL=$(echo "${RANK}" | \
        grep -o "[0-9]*" )
    filePrintf "\"level\":%s," "${LEVEL}"

    # Get School
    # shellcheck disable=SC2001
    SCHOOL=$(echo "${RANK}" | \
        sed "s/^[^-]*-\s*//g" )
    filePrintf "\"school\":\"%s\"," "${SCHOOL}"

    # Get Cast time 
    CAST_TIME=$(echo "${CURRENT_SPELL}" | \
        grep -o "<div><strong>Temps d'incantation</strong>[^<]*</div>" | \
        sed "s/^[^:]*:\s*//g" | \
        sed "s/<\/div>//g" )
    filePrintf "\"cast\":\"%s\"," "${CAST_TIME}"

    # Get Range
    RANGE=$(echo "${CURRENT_SPELL}" | \
        grep -o "<div><strong>Portée</strong>[^<]*</div>" | \
        sed "s/^[^:]*:\s*//g" | \
        sed "s/<\/div>//g" )
    filePrintf "\"range\":\"%s\"," "${RANGE}"

    # Get Component Object
    COMPONENTS=$(echo "${CURRENT_SPELL}" | \
        grep -o "<div><strong>Composantes</strong>[^<]*</div>" | \
        sed "s/^[^:]*:\s*//g" | \
        sed "s/<\/div>//g" )
    filePrintf "\"components\":{"

    # Get Component V proprety 
    filePrintf "\"v\":"
    if echo "${COMPONENTS}" | grep -qi "V"; then
        filePrintf "true"
    else
        filePrintf "false"
    fi   
    filePrintf ","

    # Get Component S proprety 
    filePrintf "\"s\":"
    if echo "${COMPONENTS}" | grep -qi "S"; then
        filePrintf "true"
    else
        filePrintf "false"
    fi   
    filePrintf ","

    # Get Component M proprety
    filePrintf "\"m\":"
    if echo "${COMPONENTS}" | grep -qi "M"; then
        filePrintf "true"
    else
        filePrintf "false"
    fi   
    filePrintf ","

    # Get Component Other proprety
    if echo "${COMPONENTS}" | grep -qi "("; then 
        OTHER_COMPONENTS="$(echo "${COMPONENTS}" | sed "s/.*(//g" | sed "s/).*//g")"
    fi
    filePrintf "\"others\":\"%s\"" "${OTHER_COMPONENTS}" 

    # End Components Object
    filePrintf "},"

    # Get Duration
    DURATION=$(echo "${CURRENT_SPELL}" | \
        grep -o "<div><strong>Durée</strong>[^<]*</div>" | \
        sed "s/^[^:]*:\s*//g" | \
        sed "s/<\/div>//g" )
    filePrintf "\"duration\":\"%s\"," "${DURATION}"

    # Get description
    DESCRIPTION=$(echo "${CURRENT_SPELL}" | \
        grep -o "<div class=\"description\">.*</div>" | \
        sed "s/<div[^>]*>//g" | \
        sed "s/<\/div>.*//g" | \
        sed 's/"/\\"/g')
    filePrintf "\"description\":\"%s\"," "${DESCRIPTION}"

    # Get all classes 
    filePrintf "\"classes\":["
    CLASSES=$(echo "${CURRENT_SPELL}" | \
        grep -zo "<div class='classe'>[^<]*</div>" | \
        sed "s/<div class='classe'>/\"/g" | \
        sed "s/<\/div>/\",/g" | \
        tr -d '\0' | \
        sed "s/,$//g" )
    filePrintf "${CLASSES}"
    filePrintf "]"

    # End object in JSON
    filePrintf "}"

    # Reset print line
    printf "\r"

    # Add ',' only if not last spell
    if [ "${SPELL_URL}" != "${URL_ARRAY[-1]}" ] ; then
        filePrintf ","
    fi
done

# End list
filePrintf "]"

printf "\n\n✨ Done and saved into '%s'.\n" "${FILENAME}"