#!/bin/bash
function writeHeader() {
  cat <<'EOF' > Genereated.aml
/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160422-64(RM)
 * Copyright (c) 2000 - 2016 Intel Corporation
 *
 * Disassembling to non-symbolic legacy ASL operators
 *
 * Disassembly of iASLyvyJ42.aml, Sun Feb 11 12:35:37 2018
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00001AD2 (6866)
 *     Revision         0x01
 *     Checksum         0x48
 *     OEM ID           "NICO"
 *     OEM Table ID     "X299"
 *     OEM Revision     0x00000000 (0)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20160422 (538313762)
 */
DefinitionBlock ("", "SSDT", 1, "NICO", "X299", 0x00000000)
{
    External (GFX0, DeviceObj)    // (from opcode)
    External (GPRW, MethodObj)    // 2 Arguments (from opcode)
    External (UPSB, DeviceObj)    // (from opcode)
EOF
}
function writeDefs() {
    cat <<'EOF' | sed -e "s/__PATH__/${acPath}/g" >> Genereated.aml
    External (__PATH__, DeviceObj)    // (from opcode)
EOF
}
function writeScopes() {
  # newCompatible=$(echo ${compatible[@]}| awk -F',' '{print ($3","$4)}'| sed -e 's/"//g')
  cat <<'EOF' | sed -e "s/__PATH__/${acPath}/g" -e "s/__SLOT__/'${slot}'/g" -e "s/__DEVICE_TYPE__/'${devTpe}'/g" -e "s|__MODEL__|'${model}'|g" -e "s/__COMPATIBLE__/'${compatible}'/g" -e "s/__NAME__/'${name}'/g" -e "s/__DEVICE_ID__/${dh}/g" -e "s/\'/\"/g" >> Genereated.aml


    Scope (\__PATH__)
      {
          OperationRegion (PCIS, PCI_Config, Zero, 0x0100)
          Field (PCIS, AnyAcc, NoLock, Preserve)
          {
              PVID,   16,
              PDID,   16
          }

          Method (_PRW, 0, NotSerialized)  // _PRW: Power Resources for Wake
          {
              Return (GPRW (0x69, 0x04))
          }

          Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
          {
              Store (Package (0x0E)
                  {
                      "built-in",
                      Buffer (One)
                      {
                           0x00
                      },

                      "device-id",
                      Buffer (0x04)
                      {
                           __DEVICE_ID__
                      },

                      "AAPL,slot-name",
                      Buffer (0x07)
                      {
                          __SLOT__
                      },

                      "device_type",
                      Buffer (0x13)
                      {
                          __DEVICE_TYPE__
                      },

                      "model",
                      Buffer (0x4A)
                      {
                          __MODEL__
                      },

                      "compatible",
                      Buffer (0x0D)
                      {
                          __COMPATIBLE__
                      },

                      "name",
                      Buffer (0x10)
                      {
                          __NAME__
                      }
                  }, Local0)
              DTGP (Arg0, Arg1, Arg2, Arg3, RefOf (Local0))
              Return (Local0)
        }
      }
EOF
}

function writeFooter(){
  cat <<'EOF' >> Genereated.aml
    Method (DTGP, 5, NotSerialized)
      {
          If (LEqual (Arg0, ToUUID ("a0b5b7c6-1318-441c-b0c9-fe695eaf949b")))
          {
              If (LEqual (Arg1, One))
              {
                  If (LEqual (Arg2, Zero))
                  {
                      Store (Buffer (One)
                          {
                               0x03
                          }, Arg4)
                      Return (One)
                  }

                  If (LEqual (Arg2, One))
                  {
                      Return (One)
                  }
              }
          }

          Store (Buffer (One)
              {
                   0x00
              }, Arg4)
          Return (Zero)
      }
}
EOF
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
    devTpe=( $(echo "${b}" | grep "device_type"| grep -o "<.*>" | sed -e 's/<//g' -e 's/>//g') )
    model=( $(echo "${b}" | grep "model"| grep -o "<.*>" | sed -e 's/<//g' -e 's/>//g') )
    compatible=( $(echo "${b}" | grep "compatible"| grep -o "<.*>" | sed -e 's/<//g' -e 's/>//g' -e 's/"\n"/","/g' -e 's/" "/" \n "/g') )
    name=( $(echo "${b}" | grep "\"name\""| grep -o "<.*>" | sed -e 's/<//g' -e 's/>//g') )

    model=$(echo ${model[@]} | tr -d "\n\r"|sed -e 's/"//g')
    slot=$(echo ${slot[@]}| tr -d "\n\r" | sed -e 's/"//g')
    # newCompatible=$(echo ${compatible[@]}| awk -F',' '{print ($3","$4)}'| sed -e 's/"//g')
    devTpe=$(echo ${devTpe[@]}| sed -e 's/"//g')
    name=$(echo ${name[@]}| sed -e 's/"//g')


    printf "\t         \t|\t   SlotName: $slot\n"

    printf "\t         \t|\t   DeviceType: $devTpe\n"

    printf "\t         \t|\t   Model: $model\n"

    for g in "${compatible[@]}"
    do
      printf "\t         \t|\t   Compatible: "${g}"\n"
    done

    printf "\t         \t|\t   Name: $name\n"
    acPath=( $(echo "${b}" | grep "\"acpi-path\"" |sed -e 's/^.*IOACPIPlane://g' -e 's|_SB/|_SB\.|g' -e 's/@[^\/]*\//./g' -e 's/@.*$//g' -e 's|/||g') )
    printf "\t         \t|\t   Current Path: \"$acPath\"\n"
  fi
  done
echo "Creating AML Template"
writeHeader
for t in "${a[@]}"
do
  b=$(ioreg -n "${t}" -r)
  dev=($(echo "${b}" | grep "device-id" | awk '{print toupper($0)}' | grep -o "<.*>"| sed -e 's/<//g' -e 's/>//g'))
  if [ ! -z "${dev}" ] && [ "$t" != "PXSX@0" ]
  then
    acPath=( $(echo "${b}" | grep "\"acpi-path\"" |sed -e 's/^.*IOACPIPlane://g' -e 's|_SB/|_SB\.|g' -e 's/@[^\/]*\//./g' -e 's/@.*$//g' -e 's|/||g') )
    writeDefs
  fi
  done
for t in "${a[@]}"
do
  b=$(ioreg -n "${t}" -r)
  dev=($(echo "${b}" | grep "device-id" | awk '{print toupper($0)}' | grep -o "<.*>"| sed -e 's/<//g' -e 's/>//g'))
  if [ ! -z "${dev}" ] && [ "$t" != "PXSX@0" ]
  then
    hex=$(echo -n "${t}" | sed -e 's/@.*//g'| xxd -ps | sed -e ':a' -e 's/\([0-9]\{2\}\|^\)\([0-9]\{2\}\)/\1\\x\2/;ta')
    for de in "${dev[@]}"
    do
      dh=$(echo "${de}"| sed -e "s/\(..\)\(..\)\(..\)\(..\)/0x\1, 0x\2, 0x\3, 0x\4/")
    done
    slot=( $(echo "${b}" | grep "AAPL,slot-name" | grep -o "<.*>" | sed -e 's/<//g' -e 's/>//g') )
    # echo ${slot[@]}
    devTpe=( $(echo "${b}" | grep "device_type"| grep -o "<.*>" | sed -e 's/<//g' -e 's/>//g') )
    model=( $(echo "${b}" | grep "model"| grep -o "<.*>" | sed -e 's/<//g' -e 's/>//g') )
    compatible=( $(echo "${b}" | grep "compatible"| grep -o "<.*>" | sed -e 's/<//g' -e 's/>//g' -e 's/"\n"/","/g' -e 's/" "/" \n "/g') )
    name=( $(echo "${b}" | grep "\"name\""| grep -o "<.*>" | sed -e 's/<//g' -e 's/>//g') )
    acPath=( $(echo "${b}" | grep "\"acpi-path\"" |sed -e 's/^.*IOACPIPlane://g' -e 's|_SB/|_SB\.|g' -e 's/@[^\/]*\//./g' -e 's/@.*$//g' -e 's|/||g') )
    model=$(echo ${model[@]} | tr -d "\n\r"|sed -e 's/"//g')
    slot=$(echo ${slot[@]}| tr -d "\n\r" | sed -e 's/"//g')
    compatible=$(echo ${compatible[@]}| sed -e 's/"//g')
    devTpe=$(echo ${devTpe[@]}| sed -e 's/"//g')
    name=$(echo ${name[@]}| sed -e 's/"//g')

    writeScopes
  fi
  done
writeFooter
