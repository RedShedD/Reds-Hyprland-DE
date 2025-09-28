# Reds-Hyprland-DE

A custom Hyprland-based keyboard driven desktop environment for Arch Linux, inspired by RedShedD's philosophy.

## Design Principles

- **Reduce cognitive load** - As little nesting as possible, O(1)
  - Example: The terminal is used as an access portal to most apps, so you don't have to think about where to find them
  - Example: No task bar. You see what exists. No hidden or minimized states.
  - Example: Each component of the system is controlled by 1 obvious control and one control only. No additional volume mixers and such.

- **Minimal dependencies** - Mostly independent packages with as little dependencies as possible to prevent breakage on update.
  - Example: No filemanagers with dependencies from other DEs
  
- **Single-purpose packages** - Each package should serve the thing it's used for, and nothing else.
  - Example: An app launcher just launches apps. It should NOT act as an emoji or tab selector.

- **Visual cohesion** - Everything should have consistent design and feel homogeneous


It is advised to copy this repo onto a portable drive, mount it and call the install.sh script from there, to prevent the need of isntalling git to clone the repository - keeps the system cleaner.

Don't forget to check out shortcuts.md
