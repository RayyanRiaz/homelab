# Installing Openwrt to Fritzbox 7520


This directory contains some files for 7530, but dont be confused. The openwrt webpage gives them like this:

https://openwrt.org/toh/avm/avm_fritz_box_7530#installation

So, I simply downloaded all the provided files for 7520 into this folder.

Then I copied the [python flash file](https://github.com/maurerle/fritz-tools/blob/03d3c8cee92a54dad3821cee431a63b19fe29443/fritzflash.py) into this directory. See, it is a fork of another famous repo, but this one has more support for 7520. Still, I had to manually change this a bit, by hard-coding that version 247 (my router's version) maps to FRITZ7530.bin. You can see the git diff if u r more interested.

Anyways, after that. First disable wifi, and set static ip settings for ethernet (ip=172.168.178.2, mask=255.255.255.0, gateway=172.168.178.1). Make sure to double test with `ping 192.168.178.1` before proceeding.


Afterwards, 

1. switch off the router
2. start the script (see below for the script cmd) and when it asks u to press enter,
3. switch on the router and press enter. 
4. it will auto-detect and complete the process. it will restart the router once during that.


### Script cmd:

```bash
sudo ./fritzflash.py --dev enp11s0 --initramfs ./openwrt-24.10.2-ipq40xx-generic-avm_fritzbox-7530-initramfs-uImage.itb --sysupgrade ./openwrt-24.10.2-ipq40xx-generic-avm_fritzbox-7530-squashfs-sysupgrade.bin
```





side-note:

`Einstellungen_FRITZ.Box_7520_(UI)_175.08.02_01.01.70_0110` is the backup before installing openwrt

https://www.youtube.com/watch?v=Fihchy4eISE&t=166s

https://fritz-tools.readthedocs.io/en/latest/flashing/ubuntu_1804.html
