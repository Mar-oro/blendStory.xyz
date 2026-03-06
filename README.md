# blendStory.xyz - Interactive Effects Guide

## Project Overview
**blendStory**: AI co-writing partner for authors and storytellers

**Domain**: blendstory.xyz  
**Theme**: Ravenclaw / Knowledge seeker aesthetic  
**Colors**: Dark yellow/brown (#1a160a), Golden yellow (#ffcc33), Warm matte tones

---

## Visual Effects

### Background Animation
**Hexagonal Wave Pattern** - Inspired by storiesbyjez.com

**Effect Type**: SVG-based hexagonal grid with wave propagation

### Pattern Structure
- **Hexagons**: 40px wide, arranged in honeycomb grid
- **Offset**: Alternating columns (honeycomb pattern)
- **Base color**: Dark yellow-brown (#4a3a1a)
- **Opacity**: 0.5 base opacity

### Auto Wave Pulse
- **Trigger**: Automatic, every 3-7 seconds (random interval)
- **Behavior**:
  - Wave originates from random grid position
  - Propagates outward based on distance from origin
  - Hexagons scale up (1.0 → 1.1)
  - Color changes to golden yellow (#ffcc33)
  - Border thickness increases (1.5 → 3px)
  - Fill opacity appears (0 → 0.3)
- **Duration**: 600ms per hexagon
- **Propagation**: distance × 50ms delay
- **Visual**: Golden wave of inspiration flowing across writing canvas

### Click Interaction
- **Trigger**: User clicks anywhere on background
- **Behavior**:
  - Wave originates from click position
  - Convert click (x,y) to grid position (col, row)
  - Random yellow variant per click:
    - #ffcc33 (main golden)
    - #ffdd55 (lighter)
    - #eebb22 (darker)
    - #ccaa00 (deep gold)
  - Hexagons scale larger (1.0 → 1.15)
  - Thicker borders (1.5 → 3.5px)
  - Higher fill opacity (0 → 0.4)
- **Duration**: 600ms per hexagon
- **Visual**: Click spreads golden energy from that point

### Technical Implementation
```javascript
// Auto wave
function createWave(startCol, startRow) {
    const waveColor = '#ffcc33'; // Single golden yellow
    hexagons.forEach(hex => {
        const distance = calculateDistance(hex, startPoint);
        setTimeout(() => {
            hex.scale = 1.1;
            hex.color = waveColor;
            hex.opacity = 1;
        }, distance * 50);
    });
}

// Click wave
function clickWave(clickX, clickY) {
    const randomYellow = ['#ffcc33', '#ffdd55', '#eebb22', '#ccaa00'];
    const color = randomYellow[random()];
    // Similar propagation but stronger effect
}
```

---

## Hexagon Grid Math

### Honeycomb Layout
```javascript
hexWidth = 40;
hexHeight = 46;
offsetX = col * hexWidth * 0.75; // 3/4 overlap
offsetY = row * hexHeight + (col % 2) * (hexHeight / 2); // Alternating offset
```

### Distance Calculation (Pythagorean)
```javascript
distance = √[(col₂ - col₁)² + (row₂ - row₁)²]
delay = distance × 50ms
```

---

## Color Palette - Matte Yellow Theme

| Element | Color | Hex | Usage |
|---------|-------|-----|-------|
| Background | Dark Brown-Yellow | #1a160a | Page background |
| Text | Warm Off-White | #e5e0d0 | Body text |
| Accent | Golden Yellow | #ffcc33 | Headings, hex waves |
| Borders | Dark Yellow Matte | #4a3a1a | Hex base, borders |
| Dim | Muted Brown-Yellow | #8a7a5a | Secondary text |

**Matte finish**: Low saturation for comfortable reading during long writing sessions

---

## User Experience Flow

1. **Landing**: Hexagonal golden waves pulse gently
2. **Reading**: Matte yellow tones don't strain eyes
3. **Interaction**: Click creates writing inspiration burst
4. **Engagement**: Natural, non-distracting background motion
5. **Focus**: Colors support focus on writing content

---

## Design Philosophy

**Theme**: Ravenclaw wisdom + Creative flow
- Golden waves = inspiration arriving
- Hexagons = structured knowledge/organization
- Matte colors = comfortable for extended reading
- Auto waves = constant creative energy
- Click interaction = user summons burst of inspiration

**Interaction Levels**:
- **Passive**: Auto waves (creative energy flowing)
- **Active**: Click waves (summon inspiration on demand)
- **Non-intrusive**: Designed for writers to focus on content

---

## Comparison to Other Lempyra Sites

| Site | Pattern | Colors | Feeling |
|------|---------|--------|---------|
| **blendStory** | Hexagons | Yellow/Gold | Warm inspiration |
| storiesbyjez | Hexagons | Red/Scarlet | Passionate intensity |
| jezabel.xyz | Hexagons | Orange | Intimate warmth |
| jezabel.net | Constellation | Magenta/Green | Hacker stealth |
| ManiacGaming | Triangles | Red | Aggressive chaos |
| ModUrWall | Squares | Blue/RGB | Organized creativity |

**Same tech, different aesthetics** - All use distance-based wave propagation

---

**Last Updated**: 2024-12-17  
**Status**: Live  
**Latest Version**: `blendstory-final.html`
