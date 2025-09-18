# Dynamic FOV Adjuster for Assetto Corsa

**Dynamically adjusts the Field of View for internal (cockpit, dash) and external (hood, floor, chaser) cameras, based on speed and G-forces — giving a much greater sensation of speed!**

---

## 🎮 Features

The app can be used in two modes:

### 🔹 Mode 1: Speed-Based FOV  
FOV is only affected by the **speed** of the vehicle.

### 🔹 Mode 2: Speed + G-Force-Based FOV  
FOV is affected by both the **speed** and **G-forces**.

This behavior can be toggled via the in-game menu. Simply enable or disable the **G-Force Effects** option.

<img width="433" height="369" alt="1750062320021" src="https://github.com/user-attachments/assets/9b458cb8-1a3c-47ac-854b-f40ecc9d78d2" />

---

## ⚙️ Settings Breakdown

### 🔧 Basic Settings

#### First Person Cameras
- **Enabled First Person**: Enables the effects for `'cockpit'`, `'dash'`, `'hood'`, and `'floor'` cameras.
- **Minimum First Person FOV**: FOV when the car is stationary.
- **Maximum First Person FOV**: FOV at maximum speed.
- **Maximum First Person Speed**: Speed at which the maximum FOV is applied.

#### Third Person Cameras
- **Enabled Third Person**: Enables the effects for `'chase close'` and `'chase far'` cameras.
- **Minimum Third Person FOV**: FOV when the car is stationary.
- **Maximum Third Person FOV**: FOV at maximum speed.
- **Maximum Third Person Speed**: Speed at which the maximum FOV is applied.

#### G-Force Effects
- **Enable G-Force Effects**: Toggles the use of g-forces in FOV calculation.

---

### 🧪 Advanced Settings

- **G-Force Factor Multiplier**: Multiplies the g-force effect on FOV. A higher value exaggerates the FOV change from g-forces.
- **Speed Curve Exponent**: Shapes how speed affects FOV.
  - `1` = linear effect
  - `< 1` = faster FOV change at low speeds, slower at high speeds
  - `> 1` = slower FOV change at low speeds, faster at high speeds

---

## 💡 Tips

Feel free to experiment with the **basic settings** (`min/max FOV`, `max speed`) — but use caution with the **advanced settings**, as they can lead to wild and unexpected results!

---
