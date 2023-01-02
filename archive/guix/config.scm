;; This is an operating system configuration template
;; for a "desktop" setup without full-blown desktop
;; environments.

(use-modules
  (srfi srfi-1)
  (guix channels)
  (guix inferior)
  (gnu)
  (gnu system nss)
  (gnu system setuid)
  ;; Import nonfree linux module.
  (nongnu packages linux)
  (nongnu system linux-initrd))

(use-service-modules
  xorg
  desktop)

(use-package-modules
  admin
  backup
  base
  bootloaders
  certs
  check ; python-pytest
  cmake
  commencement
  cups
  disk
  emacs
  file
  fpga ; python-myhdl
  freedesktop
  games ; cowsay
  ghostscript
  gnupg
  graphviz
  haskell-xyz
  image-viewers
  imagemagick
  irc ; weechat
  linux
  mail ; neomutt
  messaging ; weechat-matrix
  nano
  ncurses
  ninja
  package-management
  pdf
  perl
  pulseaudio
  python
  python-science
  python-xyz
  scanner
  shells
  ssh
  suckless
  terminals
  tex
  tmux
  version-control
  video
  vim
  w3m
  web-browsers
  wm
  xdisorg
  xml
  xorg)

(define %sudoers-specification
  (plain-file "sudoers" "\
              root ALL=(ALL) ALL
              %wheel ALL=(ALL) ALL
              %users ALL=(ALL) NOPASSWD: /run/current-system/profile/bin/light\n"))


(operating-system
  (host-name "leatherman")
  (timezone "Europe/Helsinki")
  (locale "fi_FI.utf8")

  (keyboard-layout (keyboard-layout "fi"))

  ;; Use the UEFI variant of GRUB with the EFI System
  ;; Partition mounted on /boot/efi.
  (bootloader
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (targets '("/boot/efi"))
      (keyboard-layout keyboard-layout)))

  ;; Nonguix kernel
  ;;(kernel linux)
  (kernel
    ;; pin kernel version to prevent rebuilds
    (let*
      ((channels
         (list (channel
                 (name 'nonguix)
                 (url "https://gitlab.com/nonguix/nonguix")
                 (commit "21d41c8dd4ad3099c5440a2413d0045a3de8f21a"))
               (channel
                 (name 'guix)
                 (url "https://git.savannah.gnu.org/git/guix.git")
                 (commit "50b8a8e8c2e56d014c304a01d85b2906cee95bcb"))))
       (inferior
         (inferior-for-channels channels)))
      (first (lookup-inferior-packages inferior "linux" "5.15.8"))))

  (initrd microcode-initrd)

  (firmware (list linux-firmware sof-firmware))

  ;; LUKS device mapping.
  (mapped-devices
    (list (mapped-device
            (source (uuid "6d2b3d2e-b68c-4441-9e86-d0821592d31d"))
            (target "guix-root")
            (type luks-device-mapping))
          (mapped-device
            (source (uuid "0592953a-0ebc-4493-8897-17fa0766f268"))
            (target "guix-home")
            (type luks-device-mapping))))

  ;; Assume the target root file system is labelled "my-root",
  ;; and the EFI System Partition has UUID 1234-ABCD.
  (file-systems (append
                  (list (file-system
                          (device (uuid "32f03e96-0dce-442c-8498-a54d65ec3fb1" 'ext4))
                          (mount-point "/boot")
                          (type "ext4")
                          (dependencies mapped-devices))
                        (file-system
                          (device (file-system-label "guix-root"))
                          (mount-point "/")
                          (type "ext4")
                          (dependencies mapped-devices))
                        (file-system
                          (device (file-system-label "guix-home"))
                          (mount-point "/home")
                          (type "ext4")
                          (dependencies mapped-devices))
                        (file-system
                          (device (uuid "DF42-4754" 'fat))
                          (mount-point "/boot/efi")
                          (type "vfat")))
                  %base-file-systems))

  (users (cons
           (user-account
             (name "coco")
             (comment "Code Monkey")
             (group "users")
             (supplementary-groups
               '("wheel"
                 "netdev"
                 "audio"
                 "video")))
           %base-user-accounts))

  ;; Add a bunch of window managers; we can choose one at
  ;; the log-in screen with F1.
  (packages
    (append
      (list
        ;; window managers
        dmenu
        bemenu
        sway
        swaybg
        swayidle
        swaylock
        waybar
        xorg-server-xwayland
        light
        acpi
        pipewire
        wev
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        bluez
        wl-clipboard
        scrot
        neofetch
        imagemagick
        kitty
        ;pulseaudio ; for pactl (used by wm-ctrl script)

        ;; other
        feh w3m mupdf sxiv imv
        gcc-toolchain ninja cmake
        gnu-make
        cowsay
        alacritty ; terminal emulator
        perl
        iotop
        borg
        gnupg
        flatpak
        tmux ranger file tree fish ; console tools
        vim neovim emacs nano ; editors
        git mercurial ; version-control
        openssh
        youtube-dl mpv ; media
        ncurses ; clear
        neomutt ; for email
        weechat weechat-matrix
        ffmpeg
        graphviz
        texlive
        pandoc
        zathura zathura-pdf-mupdf zathura-ps zathura-djvu
        pulsemixer
        xdg-utils

        ;; printing
        cups foomatic-filters hplip sane-backends ijs ghostscript 

        ;; python
        python python-pip python-numpy python-scipy python-sympy
        python-pytest python-myhdl python-lxml python-attrs
        python-ueberzug python-xlib python-pillow python-attr

        ;; hdl
        ;iverilog ; TODO: broken?
        verilator
        gtkwave
        ;yosys ; TODO: depends on iverilog

        ;; for HTTPS access
        nss-certs)
      %base-packages))

  ;; Use the "desktop" services, which include the
  ;; networking with NetworkManager, and more.
  (services
    (remove (lambda (service)
              (eq? (service-kind service) gdm-service-type))
            %desktop-services))

  (setuid-programs
    (append
      (list (file-like->setuid-program
              (file-append
                (specification->package "swaylock")
                "/bin/swaylock")))
      %setuid-programs))

  (sudoers-file %sudoers-specification)

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))

