# Autonomous-Agents-Assignment
| **Name**     | **Student Number** |
| ----------- | ----------- |
| Karl Negrillo      | C22386123       |

# Title: **Autonomous Chasing Creature**

## Project Idea
This project involves creating a 3D game where a **creature autonomously chases** an AI player in an environment. The AI player will try to avoid capture, while the creature follows using basic AI behaviors. The goal is to create a dynamic system where both entities act autonomously, with animated movements and sound effects to enhance the chase.

## Project Goals
Create a 3D environment where the AI player is autonomously chased by a creature. The AI will avoid the creature while the creature will pursue it. The project will focus on creating an engaging chase with basic AI behaviors and immersive sound and animations. The player’s role is to observe the chase without direct interaction.

## Key Features

- **Autonomy & Personality**: Both the creature and AI player act based on proximity and environmental factors, with the creature showing persistent chasing behavior and the AI reacting (running, hiding, etc.).

- **Steering Behaviors**: The creature uses **Seek** to autonomously chase the AI player, while the AI uses **Avoidance** to escape or hide when it gets too close.

- **Finite State Machine (FSM)**: Manages the creature’s and AI player’s states, such as idle, chasing, hiding, and running. 

- **Behavior Trees**: Define the creature’s decision-making process, such as when to start chasing, how to react when it loses sight of the player, and how it behaves when it catches the AI.

- **Procedural Animations**: Smooth animations for natural movements like running, hiding, and chasing, making both the creature and AI player feel alive.

- **Sound Design**: Spatialized audio enhances immersion, with growls, footsteps, and breath sounds dynamically changing as the creature gets closer.

- **AI Interactions**: The AI player reacts to the creature’s presence by running or hiding, while the creature adapts its behavior based on the AI player’s movements.

## Gameplay

- **Autonomous Creature**: The creature autonomously chases the AI player based on proximity, navigating obstacles and responding to lost sight of the AI.
  
- **Autonomous AI Player**: The AI player tries to evade capture, using obstacles and the environment to hide or run.
  
- **Chase Dynamics**: The creature pursues the AI continuously, reacting to its movements. The AI hides or runs when needed.

- **Hiding & Evasion**: The AI can hide behind obstacles or escape, forcing the creature to search for it.
  
- **Catching the AI**: The chase ends when the creature catches the AI, triggering a **catching animation**.

## XR Technologies Used
  
- **Spatial Audio**: Dynamic sound effects that increase in volume as the creature gets closer.
  
- **VR Interactions**: The user observes the chase in an immersive VR environment with dynamic sounds and actions.

## Tools and Resources

- **Godot Engine**
  
- **Mixamo**: pre-made 3D models and animations  This saves time on animation work and provides a wide variety of natural, realistic animations.
  
- **Blender**
  
- will link more later on the project.