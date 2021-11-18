pacman -Syu xorg xorg-server lightdm lightdm-gtk-greeter xfce4 accountsservice virtualbox-guest-utils xf86-video-vmware
sudo nano /etc/lightdm/lightdm.conf # uncomment and edit: [Seat: *] ... greeter-session=lightdm-gtk-
sudo systemctl enable --now vboxservice.service
sudo systemctl enable --now lightdm.service

sudo pacman -S base-devel