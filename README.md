# 🎮 Pinto 2D Top-Down Survival Arena

<div align="center">

<img src="assets/pinto.jpg" alt="Pinto the Cyber Hero" width="220" />

### **A Fast-Paced 2D Pixel-Art Roguelite Survival Arena in Godot 4**
*เอาชีวิตรอดจากคลื่นมอนสเตอร์ 5 Wave, อัปเกรดความสามารถแบบ Roguelite และโค่นบอสใหญ่ไปกับน้อง Pinto!*

[![Godot Engine](https://img.shields.io/badge/Godot_Engine-4.x-478CBF?style=for-the-badge&logo=godotengine&logoColor=white)](https://godotengine.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Art Style](https://img.shields.io/badge/Art_Style-Pixel_Art-blueviolet?style=for-the-badge)](https://itch.io/game-assets/free/tag-top-down)
[![Design Guide](https://img.shields.io/badge/Architecture-Catlike_Coding-brightgreen?style=for-the-badge)](https://catlikecoding.com/godot/true-top-down-2d/)

</div>

---

## 📖 เกี่ยวกับเกม (About The Game)

**Pinto 2D Top-Down Survival Arena** เป็นเกมแอ็กชันเอาชีวิตรอดมุมมองด้านบน (True Top-Down 2D) สไตล์ Roguelite / Horde Survival สร้างขึ้นด้วย **Godot Engine 4** โดยผู้เล่นจะได้รับบทเป็น **"น้อง Pinto"** หุ่นยนต์หัวกล่องสุดน่ารักที่ต้องต่อสู้เอาชีวิตรอดจากการรุกรานของเหล่ามอนสเตอร์ไซเบอร์ทั้งหมด 5 Waves และเผชิญหน้ากับบอสใหญ่ **Giga Null** ใน Wave สุดท้าย!

> **Pinto 2D Top-Down Survival Arena** is a retro pixel-art horde survival roguelite built in **Godot 4**, following the true top-down 2D architectural principles of [Catlike Coding](https://catlikecoding.com/godot/true-top-down-2d/). Control Pinto, auto-fire at oncoming monster swarms, gather XP gems, draft build-defining upgrades, and defeat the climatic Wave 5 Boss!

---

## ✨ ฟีเจอร์หลัก (Key Features)

- 🤖 **Responsive 8-Directional Kinematics**: ควบคุมน้อง Pinto เคลื่อนที่ได้อย่างอิสระ 8 ทิศทาง พร้อมแอนิเมชัน Pixel Art 4 สถานะ (`idle`, `walk`, `hurt`, `death`)
- 🎯 **Auto-Attack Combat System**: ตรวจจับและยิงกระสุนใส่มอนสเตอร์ที่ใกล้ที่สุดอัตโนมัติ (รองรับ Multi-shot, Bullet Pierce, Attack Speed)
- 💥 **Floating Damage Numbers**: ตัวเลขดาเมจลอยขึ้นเหนือหัวมอนสเตอร์เมื่อถูกโจมตี (ตัวเลขสีขาวสำหรับ Hit ปกติ และสีทองสำหรับ Critical Hit)
- 👾 **5-Wave Escalation & Multi-Phase Boss**:
  - **4 มอนสเตอร์พื้นฐาน**: `Slime` (ดึ๋งๆ อึด), `Bat` (กระพือปีกบินไว), `Drone` (ลอยยิงกระสุนสวน), `Golem` (เดินย่างสามขุมชนหนัก)
  - **Wave 5 Boss ("Giga Null")**: บอสใหญ่ 3 Phase พร้อมท่ายิงวงแหวน พุ่งชนแบบ Telegraphed และเรียกลูกสมุน
- 🃏 **Roguelite Upgrade Cards**: สะสม Gem XP เพื่อเลเวลอัปและสุ่มการ์ด 3 ใบจากทั้งหมด 10 สายพลัง (เช่น เพิ่มจำนวนกระสุน, ทะลวงเกราะ, ฮีลฉุกเฉิน, ขยายรัศมีแม่เหล็ก)
- 🗺️ **True Top-Down 2D Viewport**: ความละเอียดฐาน 640x360 ขยายเต็มหน้าจอ 1080p/1440p/4K คมชัด ไม่มีขอบดำ พร้อมระบบ Y-Sorting จัดลำดับความลึก
- 🔊 **Retro Chiptune Polyphonic Audio**: ระบบเสียงสังเคราะห์ 16-Bit ครบวงจร (เสียงยิง, ชน, สไลม์ตาย, เก็บ Gem, เลเวลอัป, บอสเตือนภัย และเพลง BGM วนลูป)
- 💾 **Score & Data Persistence**: ระบบบันทึกคะแนนสูงสุด (High Score) และเวลาเอาชีวิตรอดลงไฟล์ JSON อัตโนมัติ

---

## 🎮 วิธีการควบคุม (Controls)

| ปุ่มกด (Key) | คำสั่ง (Action) |
| :--- | :--- |
| **`W / A / S / D`** หรือ **`ปุ่มลูกศร`** | เดิน 8 ทิศทาง (Move Pinto) |
| **`อัตโนมัติ (Auto)`** | โจมตีมอนสเตอร์ที่ใกล้ที่สุด (Auto-Attack) |
| **`อัตโนมัติ (Auto)`** | แม่เหล็กดูด Gem XP เข้าหาตัว (XP Magnet) |
| **`Spacebar / คลิกเมาส์`** | เลือกการ์ดอัปเกรดเมื่อเลเวลอัป (Select Upgrade) |
| **`Esc / P`** | หยุดเกมชั่วคราว (Pause Game) |

---

## 👾 รายชื่อมอนสเตอร์ (Enemy Catalog)

| มอนสเตอร์ | สไตล์การเคลื่อนไหว | จุดเด่น | Gem Drop |
| :--- | :--- | :--- | :---: |
| **Slime** | กระโดดยุบ-ยืดตัว (7 FPS) | พลังชีวิตปานกลาง เดินตามผู้เล่นเป็นกลุ่ม | Bronze (1 XP) |
| **Bat** | ขยับปีกบินเร็ว (8 FPS) | วิ่งเร็ว โฉบเข้าหาผู้เล่นได้ไว | Bronze (1 XP) |
| **Drone** | ลอยตัวไอพ่นกะพริบ (6 FPS) | ยิงกระสุนสวนกลับใส่ผู้เล่น | Silver (5 XP) |
| **Golem** | ก้าวเดินหนักแน่น (6 FPS) | ตัวใหญ่ เลือดเยอะ ต้านแรงกระแทก (Knockback) | Gold (20 XP) |
| **Giga Null (Boss)** | ชาร์จคอร์พลังงาน (6 FPS) | บอสใหญ่ Wave 5 มี 3 Phase, ยิงกระสุนรอบตัว และเรียกลูกสมุน | Boss Gem (100 XP) |

---

## 🃏 การ์ดอัปเกรด (Upgrade Modifiers)

| การ์ด | ผลของพลัง |
| :--- | :--- |
| ⚡ **Attack Speed** | เพิ่มความเร็วในการยิงกระสุน (+15% Fire Rate) |
| 💥 **Bullet Damage** | เพิ่มพลังโจมตีของกระสุน (+20% Damage) |
| 🔱 **Multi-Shot** | เพิ่มจำนวนกระสุนยิงกระจายพร้อมกัน (+1 Additional Projectile) |
| 🏹 **Bullet Pierce** | กระสุนทะลุผ่านตัวมอนสเตอร์ (+1 Pierce Target) |
| 👟 **Move Speed** | เพิ่มความเร็วในการเคลื่อนที่ของน้อง Pinto (+15% Move Speed) |
| ❤️ **Max Health** | เพิ่มพลังชีวิตสูงสุดและฟื้นฟูเลือด (+25 Max HP & Heal) |
| 🌿 **Health Regen** | ฟื้นฟูเลือดอัตโนมัติต่อเนื่อง (+1 HP/sec) |
| 🔭 **Attack Range** | เพิ่มระยะการล็อกเป้าและระยะยิง (+25% Targeting Range) |
| 🧲 **XP Magnet** | ขยายรัศมีแม่เหล็กดูด Gem XP จากระยะไกล (+40% Magnet Radius) |
| 💖 **Emergency Heal** | ฟื้นฟูพลังชีวิตทันที 100% (Instant Full Heal) |

---

## 📁 โครงสร้างโปรเจกต์ (Project Structure)

```
pinto-2d-top-down/
├── assets/                    # Assets ภายนอก (Banner & Reference)
│   └── pinto.jpg              # ภาพต้นฉบับน้อง Pinto
│
└── new-game-project/          # โฟลเดอร์โปรเจกต์ Godot 4
    ├── project.godot          # การตั้งค่า Engine, Viewport, Input Map
    │
    ├── autoload/              # Singletons แกนกลาง
    │   ├── audio_manager.gd   # ระบบเสียง Chiptune Polyphonic SFX & BGM
    │   ├── event_bus.gd       # Signal Bus กระจาย Event ทั่วทั้งเกม
    │   ├── game_state.gd      # จัดการสเตตัส เลเวล XP และคลื่นมอนสเตอร์
    │   ├── save_manager.gd    # บันทึกและโหลด High Score ลง JSON
    │   └── upgrade_catalog.gd # แค็ตตาล็อกการ์ดอัปเกรดทั้ง 10 สาย
    │
    ├── assets/                # SpriteSheets, SFX WAVs, UI Icons
    │   ├── sprites/           # Sprites ของ Pinto, มอนสเตอร์, และ Gem
    │   ├── sfx/               # ไฟล์เสียงเอฟเฟกต์ WAV
    │   └── ui/                # Icons สำหรับการ์ดอัปเกรด
    │
    ├── scenes/                # Scene ทั้งหมดในเกม
    │   ├── main.tscn          # Scene หลักประกอบฉาก กล้อง HUD และ Spawner
    │   ├── player/            # น้อง Pinto (player.tscn / pinto_frames.tres)
    │   ├── enemies/           # มอนสเตอร์ 4 ชนิด และบอส Giga Null
    │   ├── weapons/           # กระสุนของ Pinto และกระสุนของศัตรู
    │   ├── pickups/           # Gem XP (Bronze, Silver, Gold, Boss)
    │   ├── world/             # แผนที่ Arena, กำแพง, Props, และ Spawner
    │   └── ui/                # HUD, การ์ดอัปเกรด, Damage Number, Victory/Game Over
    │
    └── tests/                 # E2E Headless Test Suites 15 ชุด (144+ Tests)
```

---

## 🚀 วิธีการเปิดเล่นเกม (How to Run)

1. ติดตั้ง **[Godot Engine 4](https://godotengine.org/)** (เวอร์ชัน 4.2 ขึ้นไป)
2. โคลน Repository นี้:
   ```bash
   git clone https://github.com/Theeraphat-S/pinto-2d-top-down.git
   ```
3. เปิด Godot Engine แล้วกด **Import** -> เลือกไฟล์ `new-game-project/project.godot`
4. กดปุ่ม **F5** (หรือปุ่ม **Play ▶️** มุมขวาบน) เพื่อเริ่มเล่นเกมได้ทันที!

---

## 📚 อ้างอิง & แหล่งที่มา (Credits & References)

- **Architecture Guide**: [Catlike Coding: True Top-Down 2D in Godot 4](https://catlikecoding.com/godot/true-top-down-2d/) by *Jasper Flick*
- **Character Design**: น้อง **Pinto** Cyber Hero
- **Engine**: [Godot Engine 4](https://godotengine.org/)

---

<div align="center">
  <sub>Developed with ❤️ using Godot 4 & Multi-Agent Pair Programming</sub>
</div>
