#!/bin/bash

function writeScopes() {
  sample=$(cat sample_aml)
  newTemp=$(echo "${sample}" | sed -e "s/__PATH__/'${acPath}'/g" -e "s/__SLOT__/"${slot}"/g" -e "s/__DEVICE_TYPE__/"${devTpe}"/g" -e "s/__MODEL__/"${model}"/g" -e "s/__COMPATIBLE__/"${g}"/g" -e "s/__NAME__/"${name}"/g" -e "s/__DEVICE_ID__/'${dh}'/g")
  echo ${newTemp}
}

whoReg=( $(ioreg -n AppleACPIPCI -r | grep "^  +-o.*"  | grep "  +-o ....\@" | sed -e 's/^  +-o //g' -e 's/  <class.*//g') )
for i in "${whoReg[@]}"
do
  a+=( $(ioreg -n $i -r | grep "   +-o.*" | grep "   +-o ....\@" | sed -e 's/    +-o//g' -e 's/  <class.*//g' -e 's/^  .*//g' -e '/^$/d') )
done
printf "\nPCI Device Location     |\t Device Info\n" | column
echo "_______________________________________________________"
for t in "${a[@]}"
do
  b=$(ioreg -n "${t}" -r)
  dev=($(echo "${b}" | grep "device-id" | awk '{print toupper($0)}' | grep -o "<.*>"| sed -e 's/<//g' -e 's/>//g'))
  if [ ! -z "${dev}" ] && [ "$t" != "PXSX@0" ]
  then
    echo
    printf "Device: $t\t  \n"|column
    hex=$(echo -n "${t}" | sed -e 's/@.*//g'| xxd -ps | sed -e ':a' -e 's/\([0-9]\{2\}\|^\)\([0-9]\{2\}\)/\1\\x\2/;ta')
    printf "HexValue: $hex\t  \n"|column
    for de in "${dev[@]}"
    do
      dh=$(echo "${de}"| sed -e "s/\(..\)\(..\)\(..\)\(..\)/0x\1, 0x\2, 0x\3, 0x\4/")
      echo "                        |          DeviceId: "${dh}""
    done
    # printf "\t  |\t   DeviceId: \"$dev\"\n"
    slot=( $(echo "${b}" | grep "AAPL,slot-name" | grep -o "<.*>" | sed -e 's/<//g' -e 's/>//g') )
    printf "\t         \t|\t   SlotName: $slot\n"
    devTpe=( $(echo "${b}" | grep "device_type"| grep -o "<.*>" | sed -e 's/<//g' -e 's/>//g') )
    printf "\t         \t|\t   DeviceType: $devTpe\n"
    model=( $(echo "${b}" | grep "model"| grep -o "<.*>" | sed -e 's/<//g' -e 's/>//g') )
    printf "\t         \t|\t   Model: $model\n"
    compatible=( $(echo "${b}" | grep "compatible"| grep -o "<.*>" | sed -e 's/<//g' -e 's/>//g' -e 's/"\n"/","/g' -e 's/" "/" \n "/g') )
    for g in "${compatible[@]}"
    do
      printf "\t         \t|\t   Compatible: "${g}"\n"
    done
    name=( $(echo "${b}" | grep "\"name\""| grep -o "<.*>" | sed -e 's/<//g' -e 's/>//g') )
    printf "\t         \t|\t   Name: $name\n"
    acPath=( $(echo "${b}" | grep "\"acpi-path\"" |sed -e 's/^.*IOACPIPlane://g' -e 's|_SB/|_SB\.|g' -e 's/@[^\/]*\//./g' -e 's/@.*$//g' -e 's|/||g') )
    printf "\t         \t|\t   Current Path: \"$acPath\"\n"
    writeScopes >> Genereated.aml
  fi
  done
