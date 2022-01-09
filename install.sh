

cat pkg.txt | while read line 
do
    echo "INSTALLING: ${line}"
    sudo pacman -S --noconfirm  ${line}
    yay -S --noconfirm --needed ${line}

done
yay -S --noconfirm --needed - < pkg.txt
#echo -ne "

gpu_type=$(lspci)
echo $gpu_type
#if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
#    pacman -S nvidia --noconfirm --needed
#	nvidia-xconfig
#elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
#    pacman -S xf86-video-amdgpu --noconfirm --needed
#elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
#    pacman -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa --needed --noconfirm
#elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
#    pacman -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa --needed --noconfirm
#fi
