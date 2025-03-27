# Homses Battle

[![Unreal Engine](https://img.shields.io/badge/Engine-UnrealEngine--AngelScript--5.4.2-blue)](https://angelscript.hazelight.se/)
[![AngelScript](https://img.shields.io/badge/Scripting-AngelScript-orange)](https://www.angelcode.com/angelscript/)

Homses Battle is an action-oriented game developed using Hazelight's modified version of Unreal Engine 5 with AngelScript support. Currently, the project is focused on developing robust character gameplay mechanics. The plan is to further explore sophisticated AI behaviors at a later stage once a solid foundation is established.

## Table of Contents
- [Project Overview](#project-overview)
- [Key Features](#key-features)
    - [Capabilities](#capabilities)
    - [Characters](#characters)
    - [Abilities System](#abilities-system)
    - [Projectile System](#projectile-system)
    - [AI and Behavior Trees](#ai-and-behavior-trees)
    - [Components and Subsystems](#components-and-subsystems)
    - [Data Structures](#data-structures)
    - [Utilities and Helpers](#utilities-and-helpers)
- [Installation and Usage Instructions](#installation-and-usage-instructions)
- [Acknowledgments](#acknowledgments)

## Project Overview
- **Engine:** [Hazelight’s UnrealEngine-Angelscript-5.4.2](https://github.com/Hazelight/UnrealEngine-Angelscript/releases/tag/v5.4.2-angelscript)
- **Scripting:** AngelScript
- **Primary Focus:** Fast-paced action gameplay and sophisticated AI behaviors
- **Development:** Solo programming and design, supported by external art and animations

## Key Features

### Capabilities
- Modular approach utilizing the Capabilities Pattern, enhancing flexibility and scalability.
- Clearly defined components and behaviors for projectiles and characters, aiding rapid development and iterations.

### Characters
- **Base Characters:** `HomseCharacterBase`, extended into player (`HomsePlayerCharacter`) and enemy (`HomseEnemyBase`) classes.
- **AI Controllers:** `HomseEnemyAIControllerBase`, managing AI-driven enemy behaviors.
- **Player Controls:** Managed via `PlayerController` and associated input handling components.

### Abilities System
- Modular conditions and modifiers enhance character interactions, abilities, and combat dynamics:
    - Conditions (e.g., cooldowns, grounded checks)
    - Modifiers (movement enhancements, camera effects, combat hit boxes, projectile spawning, etc.)

### Projectile System
- Robust projectile handling with extensive customization capabilities:
    - Movement (acceleration, bounce, gravity, drag)
    - Combat effects (damage calculation, collision handling, obstacle avoidance)
    - Spawning and destruction behaviors
    - Visualization of projectile trajectories

### AI and Behavior Trees
- Advanced AI behavior management leveraging behavior trees:
    - **Decorators:** Target visibility and range checking.
    - **Services:** Dynamic updating of target locations and distances.
    - **Tasks:** AI combat actions, movement tasks (finding cover, patrol, movement to target), and blackboard manipulation tasks.

### Components and Subsystems
- Extensive component-based architecture for flexibility and modularity:
    - Character components (Health, Movement, Abilities)
    - Projectile components (Collision, Tracking, Bounce)
    - `EntityRegistrySubsystem` for efficient entity management.

### Data Structures
- Clearly structured data for projectiles, effects, and other gameplay elements:
    - Damage handling and hit effects.
    - Customizable projectile properties and behaviors through various data components.

### Utilities and Helpers
- Supporting utilities enhance game mechanics and development workflow:
    - Actor tracking and trajectory prediction.
    - Camera shake effects for impact feedback.
    - Tagging, timing systems, and visualization aids for debugging and gameplay polish.

## Installation and Usage Instructions
1. Clone the repository.
2. Follow [Hazelight’s AngelScript Engine Installation Guide](https://angelscript.hazelight.se/getting-started/installation/) to set up UnrealEngine-Angelscript-5.4.2.
3. Open and compile the project using your IDE.

## Acknowledgments
- Special thanks to [Tove Dahlberg](https://toveadahlberg.artstation.com/) for their invaluable artistic contributions.
- Hazelight for providing their modified engine version.
- The AngelScript community for continuous improvements and support.