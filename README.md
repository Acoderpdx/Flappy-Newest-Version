# Flappy Bird Clone

## Overview
This project is a custom version of the classic Flappy Bird game built using Flutter. The game features a bird that the player controls to navigate through obstacles while trying to achieve the highest score possible.

## Setup Instructions

1. **Install Flutter**: Ensure you have Flutter installed on your machine. Follow the official Flutter installation guide.

2. **Create a New Flutter Project**: Open your terminal and run:
   ```
   flutter create flappy_bird_clone
   cd flappy_bird_clone
   ```

3. **Set Up Project Structure**: Create the necessary directories and files as per the project tree structure.

4. **Add Assets**: Place your custom images (`bird.png`, `obstacle.png`, `background.png`) in the `assets/images` directory.

5. **Update pubspec.yaml**: Add the assets to the `pubspec.yaml` file:
   ```yaml
   flutter:
     assets:
       - assets/images/bird.png
       - assets/images/obstacle.png
       - assets/images/background.png
   ```

6. **Implement Game Logic**:
   - In `lib/main.dart`, set up the main app and route to the GameScreen.
   - In `lib/screens/game_screen.dart`, implement the game logic, including bird movement and collision detection.
   - Use `lib/widgets/bird_widget.dart`, `lib/widgets/obstacle_widget.dart`, and `lib/widgets/background_widget.dart` to create the visual components.

7. **Define Constants**: In `lib/utils/constants.dart`, define the necessary constants for the game.

8. **Run the App**: Open Xcode and set up the iOS simulator. In your terminal, run:
   ```
   flutter run
   ```

9. **Test the Game**: Play the game in the simulator, ensuring that the bird can fly, obstacles appear, and the game tracks the score.

10. **Customize**: Modify the images and constants to further customize your game.

11. **Debugging**: Use Flutter's debugging tools to troubleshoot any issues that arise during development.

12. **Documentation**: Update `README.md` with instructions on how to play and customize the game.

## Gameplay Details
- The player taps the screen to make the bird fly.
- The objective is to navigate through the gaps between obstacles without hitting them.
- The game tracks the score based on the number of obstacles successfully passed.

## Customization
- Replace the images in the `assets/images` directory with your own to change the appearance of the bird, obstacles, and background.
- Modify the constants in `lib/utils/constants.dart` to adjust game mechanics such as gravity, speed, and dimensions.

## How to create and upload a new game branch (e.g., "lions-mane-pooping-title-screen")

1. Open your terminal and navigate to your project directory:
   ```
   cd "/Users/aidanbernard/Documents/Vibe coding/Vibe Coding/Flappy-Newest-Version-main"
   ```

2. Stage all your changes:
   ```
   git add .
   ```

3. Commit your changes (optional but recommended):
   ```
   git commit -m "Implement lions mane pooping title screen"
   ```

4. Create and switch to a new branch (e.g., "lions-mane-pooping-title-screen"):
   ```
   git checkout -b lions-mane-pooping-title-screen
   ```

5. Push the new branch to your remote repository (replace "origin" with your remote name if different):
   ```
   git push -u origin lions-mane-pooping-title-screen
   ```

6. You can now share this branch or open a pull request on GitHub to merge it.

## License
This project is open-source and available for modification and distribution. Enjoy creating your own version of Flappy Bird!