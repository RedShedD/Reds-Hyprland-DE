# Reds-Hyprland-DE

A custom Hyprland-based desktop environment for Arch Linux, inspired by RedShedD's philosophy.

It aims to be as lightweight and portable as possible, while also reducing cognitive load.
It is not aimed to be user friendly, it's meant to be stable and efficient, both on hardware as well as user level.

- **Reduce cognitive load** - As little nesting as possible, O(1)
  - Example: You think about something you want to get done, you do it with as little searching as possible.

- **Single control per component** - Each part of the system is controlled by 1 control and one control only
  - Example: Each app controls its own volume (while being influenced by the master volume). No additional volume mixers and such.

- **Single-purpose packages** - Each package should serve the thing it's used for, and nothing else.
  - Example: An app launcher just launches apps. It should NOT act as an emoji or tab selector.

- **Minimal dependencies** - Mostly independent packages with as little dependencies as possible to prevent breakage on update.

- **Clean removal** - Packages should be as easily and tracelessly removable as possible

- **Portable design** - The system should be as portable and abstract as possible to prevent unused features
  - Example: Trackpad gestures will not be used at a desktop. Thus no trackpad features

- **Visual cohesion** - Apps should have consistent design and feel homogeneous
