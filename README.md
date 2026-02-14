# ⚒️ Blacksmith - Incremental RPG

An incremental RPG about crafting legendary weapons. Build your smithy, mine ore, and create powerful weapons!

## 🎮 Play Online

**Web Version (HTML5):** https://filola.github.io/blacksmith-app

Play directly in your browser on desktop or mobile!

## 📋 Features

- **Incremental Gameplay** - Automate and expand your operations
- **Mining System** - Mine ore, collect resources, and manage workers
- **Crafting** - Create legendary weapons with unique properties
- **Adventures** - Send out heroes on quests to earn rewards
- **Progression** - Multiple tiers of upgrades and unlockables
- **Mobile Friendly** - Plays smoothly on phones and tablets

## 🛠️ Development

### Requirements
- Godot 4.6
- GDScript

### Local Setup

```bash
# Clone the repository
git clone https://github.com/filola/blacksmith-app.git
cd blacksmith-app

# Open in Godot 4.6
godot

# Run the game
F5 (or Play button)
```

### Export to HTML5

The game is automatically exported to GitHub Pages on every push to the `main` branch via GitHub Actions.

To manually export:

1. Open the project in Godot 4.6
2. Go to **File > Export Project**
3. Select "Web" preset
4. Click "Export Project"

## 📁 Project Structure

```
├── scenes/           # Game scenes
├── scripts/          # GDScript files
├── resources/        # Assets and data
├── autoload/         # Autoload singletons
├── project.godot     # Project configuration
└── export_presets.cfg # Export settings
```

## 🚀 Deployment

The project uses GitHub Actions to automatically build and deploy the game to GitHub Pages:

- **Trigger:** Push to `main` branch
- **Build:** Godot 4.6 HTML5 export
- **Deploy:** GitHub Pages at https://filola.github.io/blacksmith-app

See `.github/workflows/deploy.yml` for workflow details.

## 📝 License

MIT License

## 🎨 Credits

Developed with ❤️ using Godot Engine
