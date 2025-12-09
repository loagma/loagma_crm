# 📱 Attendance System - Visual Guide

## 🎨 Screen Layouts

### 1. Main Punch Screen

```
┌─────────────────────────────────────┐
│  ← Attendance              🕐       │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐ │
│  │     🕐 02:30:45 PM            │ │
│  │   Tuesday, December 09, 2025  │ │
│  │      [John Doe]               │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  ● Currently Working          │ │
│  │  ─────────────────────────    │ │
│  │  🟢 Punch In    ⏱️ Duration   │ │
│  │   09:00 AM      5h 30m 45s    │ │
│  └───────────────────────────────┘ │
│                                     │
│         ┌─────────────┐            │
│         │             │            │
│         │   🔴 PUNCH  │            │
│         │     OUT     │            │
│         │             │            │
│         └─────────────┘            │
│    Tap to end your work day        │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Today's Summary              │ │
│  │  🟢 Punch In:    09:00 AM     │ │
│  │  🔴 Punch Out:   --:--        │ │
│  │  ⏱️ Duration:    5h 30m 45s   │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  📍 Location Status            │ │
│  │  ● Location acquired      🔄   │ │
│  │  Lat: 28.6139                 │ │
│  │  Lon: 77.2090                 │ │
│  │  Accuracy: 10.5m              │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

### 2. Punch In Dialog - Step 1 (Photo)

```
┌─────────────────────────────────────┐
│  🟢 Punch In          Step 1/3      │
│  ▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░   │
├─────────────────────────────────────┤
│                                     │
│           📷                        │
│                                     │
│      Capture Your Photo             │
│   Take a selfie to mark your        │
│        attendance                   │
│                                     │
│      ┌─────────────┐                │
│      │             │                │
│      │   [PHOTO]   │                │
│      │             │                │
│      └─────────────┘                │
│                                     │
│      ✓ Photo captured!              │
│      🔄 Retake Photo                │
│                                     │
├─────────────────────────────────────┤
│  [Back]    [Next →]         [✕]    │
└─────────────────────────────────────┘
```

### 3. Punch In Dialog - Step 2 (Bike KM)

```
┌─────────────────────────────────────┐
│  🟢 Punch In          Step 2/3      │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░   │
├─────────────────────────────────────┤
│                                     │
│           🏍️                        │
│                                     │
│    Enter Bike Kilometers            │
│   Record your bike odometer         │
│          reading                    │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🏍️ Bike Kilometers          │   │
│  │ ┌─────────────────────────┐ │   │
│  │ │ 12345              KM   │ │   │
│  │ └─────────────────────────┘ │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ ℹ️ Enter the exact reading  │   │
│  │   from your bike's odometer │   │
│  └─────────────────────────────┘   │
│                                     │
├─────────────────────────────────────┤
│  [← Back]  [Next →]         [✕]    │
└─────────────────────────────────────┘
```

### 4. Punch In Dialog - Step 3 (Confirm)

```
┌─────────────────────────────────────┐
│  🟢 Punch In          Step 3/3      │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   │
├─────────────────────────────────────┤
│                                     │
│           ✓                         │
│                                     │
│      Confirm Punch In               │
│   Review your details before        │
│        punching in                  │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🕐 Time:    09:00 AM        │   │
│  │ ─────────────────────────   │   │
│  │ 📍 Location: 28.6139,       │   │
│  │              77.2090        │   │
│  │ ─────────────────────────   │   │
│  │ 🏍️ Bike KM:  12345 KM      │   │
│  │ ─────────────────────────   │   │
│  │ 📷 Photo:   [Thumbnail]     │   │
│  └─────────────────────────────┘   │
│                                     │
├─────────────────────────────────────┤
│  [← Back]  [✓ Punch In]     [✕]    │
└─────────────────────────────────────┘
```

### 5. Attendance History Screen

```
┌─────────────────────────────────────┐
│  ← Attendance History               │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐ │
│  │ This Month (December 2025)    │ │
│  │                               │ │
│  │  📅 Days    ⏱️ Hours  🚗 Dist │ │
│  │    22       176.5h   450.5km  │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 📅 Mon, Dec 09, 2025 [✓ Comp]│ │
│  │ ─────────────────────────     │ │
│  │  🟢 Punch In    🔴 Punch Out  │ │
│  │   09:00 AM       06:00 PM     │ │
│  │ ─────────────────────────     │ │
│  │  ⏱️ 9h 0m      🚗 45.2 km     │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 📅 Sun, Dec 08, 2025 [✓ Comp]│ │
│  │ ─────────────────────────     │ │
│  │  🟢 Punch In    🔴 Punch Out  │ │
│  │   08:30 AM       05:30 PM     │ │
│  │ ─────────────────────────     │ │
│  │  ⏱️ 9h 0m      🚗 38.7 km     │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 📅 Sat, Dec 07, 2025 [⚠ Act] │ │
│  │ ─────────────────────────     │ │
│  │  🟢 Punch In    🔴 Punch Out  │ │
│  │   09:15 AM       --:--        │ │
│  │ ─────────────────────────     │ │
│  │  ⏱️ --:--      🚗 -- km       │ │
│  └───────────────────────────────┘ │
│                                     │
│         [Load More Records]         │
│                                     │
└─────────────────────────────────────┘
```

## 🎨 Color Scheme

### Primary Colors
- **Gold/Primary**: `#D7BE69` - Main theme color
- **Success/Green**: `#4CAF50` - Punch in, completed status
- **Error/Red**: `#F44336` - Punch out, errors
- **Warning/Orange**: `#FF9800` - Active status, warnings
- **Info/Blue**: `#2196F3` - Information, links

### Status Colors
- **Active**: 🟠 Orange - Currently working
- **Completed**: 🟢 Green - Day completed
- **Error**: 🔴 Red - Issues or errors
- **Neutral**: ⚪ Grey - Inactive/disabled

### Background Colors
- **Screen Background**: Grey[100] - `#F5F5F5`
- **Card Background**: White - `#FFFFFF`
- **Elevated Card**: White with shadow
- **Input Background**: Grey[50] - `#FAFAFA`

## 📐 Layout Specifications

### Spacing
- **Screen Padding**: 16px
- **Card Margin**: 16px horizontal, 8px vertical
- **Card Padding**: 20px
- **Element Spacing**: 12px between elements
- **Section Spacing**: 24px between sections

### Typography
- **Title**: 20px, Bold
- **Subtitle**: 16px, Medium
- **Body**: 14px, Regular
- **Caption**: 12px, Regular
- **Time Display**: 36px, Bold (main clock)
- **Button Text**: 16px, Medium

### Components
- **Border Radius**: 16px (cards), 12px (buttons), 8px (inputs)
- **Button Height**: 48px (primary), 40px (secondary)
- **Icon Size**: 24px (standard), 28px (large), 20px (small)
- **Avatar Size**: 60px (profile)

## 🔄 State Indicators

### Loading States
```
┌─────────────────┐
│                 │
│   ⟳ Loading...  │
│                 │
└─────────────────┘
```

### Success State
```
┌─────────────────┐
│   ✓ Success!    │
│   Message here  │
└─────────────────┘
```

### Error State
```
┌─────────────────┐
│   ✕ Error!      │
│   Error message │
└─────────────────┘
```

### Empty State
```
┌─────────────────┐
│       📋        │
│   No records    │
│     found       │
└─────────────────┘
```

## 🎯 Interactive Elements

### Punch Button (Not Punched In)
```
    ┌─────────────┐
    │             │
    │   🟢 PUNCH  │
    │      IN     │
    │             │
    └─────────────┘
  Tap to start work day
```

### Punch Button (Punched In)
```
    ┌─────────────┐
    │             │
    │   🔴 PUNCH  │
    │     OUT     │
    │             │
    └─────────────┘
   Tap to end work day
```

### Refresh Indicator
```
    Pull down to refresh
           ↓
    ┌─────────────┐
    │   ⟳ ⟳ ⟳    │
    └─────────────┘
```

## 📊 Data Display Formats

### Time Format
- **Clock**: `02:30:45 PM` (12-hour with seconds)
- **Punch Time**: `09:00 AM` (12-hour without seconds)
- **Duration**: `5h 30m 45s` or `5h 30m`

### Date Format
- **Full**: `Tuesday, December 09, 2025`
- **Short**: `Mon, Dec 09, 2025`
- **Compact**: `Dec 09`

### Distance Format
- **Kilometers**: `45.2 km` (1 decimal)
- **Meters**: `450 m` (no decimal)

### Location Format
- **Coordinates**: `28.6139, 77.2090` (4 decimals)
- **Accuracy**: `10.5m` (1 decimal)

## 🎬 Animations

### Transitions
- **Screen Navigation**: Slide (300ms)
- **Dialog Appearance**: Fade + Scale (250ms)
- **Button Press**: Scale down (100ms)
- **Loading Spinner**: Rotate (continuous)

### Haptic Feedback
- **Light**: Navigation, selection
- **Medium**: Button press, action
- **Heavy**: Success, punch in/out

## 📱 Responsive Design

### Phone (Portrait)
- Single column layout
- Full-width cards
- Stacked elements
- Bottom navigation

### Tablet (Landscape)
- Two-column layout possible
- Wider cards with max-width
- Side-by-side elements
- Optimized spacing

## ✨ Special Effects

### Card Shadows
```
Box Shadow:
- Color: Grey with 10% opacity
- Blur: 10px
- Offset: (0, 5px)
```

### Gradient Backgrounds
```
Linear Gradient:
- Start: Primary Color
- End: Primary Color (70% opacity)
- Direction: Top-left to Bottom-right
```

### Status Indicators
```
● Active   - Pulsing green dot
○ Inactive - Static grey dot
⚠ Warning  - Blinking orange dot
```

---

## 🎯 Design Principles

1. **Clarity**: Clear visual hierarchy
2. **Consistency**: Uniform spacing and colors
3. **Feedback**: Immediate response to actions
4. **Simplicity**: Minimal steps to complete tasks
5. **Accessibility**: High contrast, readable fonts
6. **Performance**: Smooth animations, fast loading

---

**Design Version**: 1.0.0  
**Last Updated**: December 9, 2025  
**Status**: ✅ Implemented
