#!/bin/bash

### AideDD Endpoint
ENDPOINT="https://www.aidedd.org/dnd-filters/sorts.php"

### JSON Creation
# File
TIMESTAMP="$(date '+%H:%M:%S-%d_%m_%Y')"
FILENAME="spells.${TIMESTAMP}.json"

# Function
function filePrintf() {
    # shellcheck disable=SC2059
    printf "${@}" >> "${FILENAME}"
}

### Script Progress 
# Variables
CLOCK=("🕛" "🕐" "🕑" "🕒" "🕓" "🕔" "🕕" "🕖" "🕗" "🕘" "🕙" "🕚")
CLOCK_LENGHT="${#CLOCK[@]}"
INDEX="1"

# Function
function progress() {
    CLOCK_INDEX="$((INDEX%CLOCK_LENGHT))"
    CLOCK_EMOJI="${CLOCK[${CLOCK_INDEX}]}"
    PERCENTAGE="$((INDEX*100/${1}))"
    
    printf "\r%s %s%% - Progress: %s/%s" "${CLOCK_EMOJI}" "${PERCENTAGE}" "$((INDEX++))" "${1}"
}

### Script Beginning
printf "🪛 AideDD Web Scrapper\n"
printf "📚 Getting Spells at address \"%s\"\n\n" "${ENDPOINT}"

# Get base DOM from the Endpoint
INITIAL_TABLE=$(curl "${ENDPOINT}" 2> /dev/null)

# Get all spell's URLs
URL_TABLE=$(echo "${INITIAL_TABLE}" | \
    grep -zo "https://www.aidedd.org/dnd/sorts.php?[^\"]*\"" | \
    tr -d '\0' | \
    sed 's/"/\n/g')

# Create array from URLs
readarray -td$'\n' URL_ARRAY <<< "${URL_TABLE}"
declare -p URL_ARRAY > /dev/null && LENGHT="${#URL_ARRAY[@]}"

# Begin JSON list
filePrintf "["

# Loop on Spells
for SPELL_URL in "${URL_ARRAY[@]}"; do
    progress "${LENGHT}"

    # Get content of Spell
    CURRENT_SPELL=$(curl "${SPELL_URL}" 2> /dev/null | grep "${SPELL_URL}")

    # Get Name
    NAME=$(echo "$CURRENT_SPELL}" | \
        grep -o "<h1>[^<]*</h1>" | \
        sed "s/<[^>]*>//g" )

    # Get Rank
    RANK=$(echo "${CURRENT_SPELL}" | \
        grep -o "<div class=\"ecole\">[^<]*</div>" | \
        sed "s/<[^>]*>//g" )

    # Get Level
    LEVEL=$(echo "${RANK}" | \
        grep -o "[0-9]*" )

    # Get School
    # shellcheck disable=SC2001
    SCHOOL=$(echo "${RANK}" | \
        sed "s/^[^-]*-\s*//g" )

    # Get Cast time 
    CAST_TIME=$(echo "${CURRENT_SPELL}" | \
        grep -o "<div><strong>Temps d'incantation</strong>[^<]*</div>" | \
        sed "s/^[^:]*:\s*//g" | \
        sed "s/<\/div>//g" )

    # Get Range
    RANGE=$(echo "${CURRENT_SPELL}" | \
        grep -o "<div><strong>Portée</strong>[^<]*</div>" | \
        sed "s/^[^:]*:\s*//g" | \
        sed "s/<\/div>//g" )

    # Get Component Object
    COMPONENTS=$(echo "${CURRENT_SPELL}" | \
        grep -o "<div><strong>Composantes</strong>[^<]*</div>" | \
        sed "s/^[^:]*:\s*//g" | \
        sed "s/<\/div>//g" )

    # Get Component V proprety 
    if echo "${COMPONENTS}" | grep -qi "V"; then V_COMP="true"; else V_COMP="false"; fi

    # Get Component S proprety 
    if echo "${COMPONENTS}" | grep -qi "S"; then S_COMP="true"; else S_COMP="false"; fi
    
    # Get Component M proprety 
    if echo "${COMPONENTS}" | grep -qi "M"; then
        M_COMP="true"
        OTHER_COMPONENTS="$(echo "${COMPONENTS}" | sed "s/.*(//g" | sed "s/).*//g")"
    else
        M_COMP="false"
        OTHER_COMPONENTS=""
    fi
    # End Components Object

    # Get Duration
    DURATION=$(echo "${CURRENT_SPELL}" | \
        grep -o "<div><strong>Durée</strong>[^<]*</div>" | \
        sed "s/^[^:]*:\s*//g" | \
        sed "s/<\/div>//g" )

    # Get description
    DESCRIPTION=$(echo "${CURRENT_SPELL}" | \
        grep -o "<div class=\"description\">.*</div>" | \
        sed "s/<div[^>]*>//g" | \
        sed "s/<\/div>.*//g" | \
        sed 's/"/\\"/g')

    # Get all classes 
    CLASSES=$(echo "${CURRENT_SPELL}" | \
        grep -zo "<div class='classe'>[^<]*</div>" | \
        sed "s/<div class='classe'>/\"/g" | \
        sed "s/<\/div>/\",/g" | \
        tr -d '\0' | \
        sed "s/,$//g" )

    # Create JSON
    filePrintf "{\"url\":\"%s\"," "${SPELL_URL}"
    filePrintf "\"name\":\"%s\"," "${NAME}"
    filePrintf "\"level\":%s," "${LEVEL}"
    filePrintf "\"school\":\"%s\"," "${SCHOOL}"
    filePrintf "\"cast\":\"%s\"," "${CAST_TIME}"
    filePrintf "\"range\":\"%s\"," "${RANGE}"
    filePrintf "\"components\":{"
    filePrintf "\"v\":%s," "${V_COMP}"
    filePrintf "\"s\":%s," "${S_COMP}"
    filePrintf "\"m\":%s," "${M_COMP}"
    filePrintf "\"others\":\"%s\"}," "${OTHER_COMPONENTS}"
    filePrintf "\"duration\":\"%s\"," "${DURATION}"
    filePrintf "\"description\":\"%s\"," "${DESCRIPTION}"
    filePrintf "\"classes\":[%s]}" "${CLASSES}"
    # End JSON

    # Avoid to add breaking ',' to last element 
    if [ "${SPELL_URL}" != "${URL_ARRAY[-1]}" ]; then
        filePrintf ","
    else
        printf '\n'
    fi
done

# End list
filePrintf "]"

printf "\n✨ Done and saved into '%s'.\n" "${FILENAME}"