# 🐉 AideDD Scrapper
A Shell Web Scrapper for [AideDD](https://aidedd.org) to get french DnD 5e informations in French !

# How to use it ?
Just run any of the scripts present here (files ending with `.sh`).

```bash
$ ./spells.sh
# ie. Here we run the script to get all the spells
```

You will the generate a JSON file with the following naming convention:
```bash
$SCRIPT_NAME.$TIMESTAMP.json
# ie. For the `spells.sh` it will be `spells.$TIMESTAMP.json` file
```

# Makerules
- help:   	Show all Makerules.
- clean:  	Clean all the JSON using the `$SCRIPT_NAME.$TIMESTAMP.json` formatting.

# License
The code is available unde the [MIT](LICENSE) License.

#
<a href="https://gitmoji.dev">
  <img
    src="https://img.shields.io/badge/gitmoji-%20😜%20😍-FFDD67.svg?style=flat-square"
    alt="Gitmoji"
  />
</a>