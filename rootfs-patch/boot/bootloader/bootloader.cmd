setenv load_addr "0x8000000"
setenv bootdir "/boot/bootloader"
setenv rootpart "mmc 1:1"
load ${rootpart} ${load_addr} ${bootdir}/bootloader.conf
env import -t ${load_addr} ${filesize}

if test "${docker_optimizations}" = "1"; then setenv extra_bootargs "${extra_bootargs} cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory swapaccount=1";fi

for con in ${console};do
	setenv extra_bootargs "${extra_bootargs} console=${con}" 
done

part uuid ${rootpart} partuuid
setenv bootargs "root=PARTUUID=${partuuid} consoleblank=0 loglevel=${kernel_log_level} ${extra_bootargs}"

load ${rootpart} ${ramdisk_addr_r} boot/${initrd}
load ${rootpart} ${kernel_addr_r} boot/${kernel}
load ${rootpart} ${fdt_addr_r} ${bootdir}/${fdtfile}
fdt addr ${fdt_addr_r}
fdt resize 65536

for file in  ${overlay_fdt_files}; do
	if load ${rootpart} ${fdtoverlay_addr_r} ${bootdir}/overlay/${file}; then
		echo "Applying kernel provided DT overlay ${file}"
		fdt apply ${fdtoverlay_addr_r} || setenv overlay_error "true"
	fi
done

if test "${overlay_error}" = "true"; then
	echo "Error applying DT overlays, restoring original DT"
	load ${rootpart} ${fdt_addr_r} ${bootdir}/${fdtfile}
else
	if load ${rootpart} ${load_addr} ${bootdir}/overlay/rockchip-fixup.scr; then
		echo "Applying kernel provided DT fixup script rochchip-fixup.scr"
		source ${load_addr}
	fi
fi
echo kernelbootargs:${bootargs}
booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}