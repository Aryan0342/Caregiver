# App Color Scheme Documentation

This document describes the complete color scheme used in the "Dag in beeld" (Day in view) Flutter app. Use these colors when building the admin panel or any other UI components to maintain visual consistency.

## Color Philosophy

The app uses a **neutral earth tone palette** designed to be:
- Calm and soothing (healthcare/communication context)
- Accessible and readable
- Modern and professional
- Non-distracting for users with communication needs

## Primary Colors

### Primary (Muted Grey-Brown)
- **Hex**: `#9A8C84`
- **RGB**: `rgb(154, 140, 132)`
- **Usage**: Primary buttons, app bar, selected states, active elements, main brand color
- **Description**: A warm, muted grey-brown that's professional yet approachable

### Primary Light (Cool Grey-Beige)
- **Hex**: `#C2BAB1`
- **RGB**: `rgb(194, 186, 177)`
- **Usage**: Secondary buttons, backgrounds, hover states, unselected category chips, containers
- **Description**: A light-medium cool grey-beige for secondary elements

### Primary Dark (Dark Grey-Brown)
- **Hex**: `#776E67`
- **RGB**: `rgb(119, 110, 103)`
- **Usage**: Darker states, text color, dark accents
- **Description**: A dark rich grey-brown for text and emphasis

## Accent Colors

### Accent (Warm Tan)
- **Hex**: `#D6BF99`
- **RGB**: `rgb(214, 191, 153)`
- **Usage**: Secondary actions, accent buttons, highlights
- **Description**: A medium warm tan for secondary actions and visual interest

### Error/Warning (Red)
- **Hex**: `#E74C3C`
- **RGB**: `rgb(231, 76, 60)`
- **Usage**: Error messages, destructive actions, warnings
- **Description**: Standard red for errors and warnings

## Background Colors

### Background Light (Cream Beige)
- **Hex**: `#F0E5D5`
- **RGB**: `rgb(240, 229, 213)`
- **Usage**: Main app background, screen backgrounds
- **Description**: A very light creamy beige that provides a warm, calm backdrop

### Surface White
- **Hex**: `#FFFFFF`
- **RGB**: `rgb(255, 255, 255)`
- **Usage**: Cards, dialogs, elevated surfaces, input fields
- **Description**: Pure white for elevated UI elements

### Secondary Container (Light Warm Tan)
- **Hex**: `#E8DDCD`
- **RGB**: `rgb(232, 221, 205)`
- **Usage**: Secondary containers, subtle backgrounds
- **Description**: A lighter warm tan for secondary containers

## Text Colors

### Text Primary (Dark Grey-Brown)
- **Hex**: `#776E67`
- **RGB**: `rgb(119, 110, 103)`
- **Usage**: Main text, headings, important labels
- **Description**: Dark grey-brown for high contrast and readability

### Text Secondary (Muted Grey-Brown)
- **Hex**: `#9A8C84`
- **RGB**: `rgb(154, 140, 132)`
- **Usage**: Secondary text, hints, placeholders, disabled states
- **Description**: Muted grey-brown for less prominent text

## Color Usage Guidelines

### Buttons
- **Primary Action**: Primary (`#9A8C84`) with white text
- **Secondary Action**: Accent/Warm Tan (`#D6BF99`) with white text
- **Success/Complete**: Primary (`#9A8C84`) with white text (same as primary)
- **Error/Destructive**: Error Red (`#E74C3C`) with white text
- **Outlined**: Transparent background with Primary border and Primary text

### Cards and Surfaces
- **Card Background**: Surface White (`#FFFFFF`)
- **Page Background**: Background Light (`#F0E5D5`)
- **Elevated Surfaces**: Surface White with subtle shadows (black at 10% opacity)
- **Secondary Containers**: Light Warm Tan (`#E8DDCD`)

### Selection States
- **Selected**: Primary (`#9A8C84`) background with white text
- **Unselected**: Primary Light (`#C2BAB1`) or transparent background with Primary text
- **Hover**: Slightly darker shade of Primary Light

### Status Indicators
- **Active/Enabled**: Primary (`#9A8C84`)
- **Pending/Warning**: Accent/Warm Tan (`#D6BF99`)
- **Error**: Error Red (`#E74C3C`)
- **Inactive/Disabled**: Text Secondary (`#9A8C84`) with reduced opacity

### Borders and Dividers
- **Primary Borders**: Primary Light (`#C2BAB1`)
- **Focused Borders**: Primary (`#9A8C84`) with 2px width
- **Subtle Dividers**: Primary Light (`#C2BAB1`)

## Material Design Integration

### Flutter Material Theme
```dart
primaryColor: #9A8C84 (Primary - Muted Grey-Brown)
primaryColorLight: #C2BAB1 (Primary Light - Cool Grey-Beige)
primaryColorDark: #776E67 (Primary Dark - Dark Grey-Brown)
secondaryColor: #D6BF99 (Accent - Warm Tan)
errorColor: #E74C3C (Error Red)
backgroundColor: #F0E5D5 (Background Light - Cream Beige)
cardColor: #FFFFFF (Surface White)
textTheme: 
  - headline: #776E67 (Text Primary)
  - body: #776E67 (Text Primary)
  - caption: #9A8C84 (Text Secondary)
```

### Material-UI (MUI) Theme
```javascript
{
  palette: {
    primary: {
      main: '#9A8C84',
      light: '#C2BAB1',
      dark: '#776E67',
    },
    secondary: {
      main: '#D6BF99',
      light: '#E8DDCD',
      dark: '#B8A585',
    },
    error: {
      main: '#E74C3C',
    },
    background: {
      default: '#F0E5D5',
      paper: '#FFFFFF',
    },
    text: {
      primary: '#776E67',
      secondary: '#9A8C84',
    },
  },
}
```

## Typography

### Font Sizes (Accessibility Optimized)
- **Display Large**: 32px, Bold
- **Display Medium**: 28px, Bold
- **Display Small**: 24px, Semi-bold (600)
- **Headline Large**: 22px, Semi-bold (600)
- **Headline Medium**: 20px, Semi-bold (600)
- **Headline Small**: 18px, Semi-bold (600)
- **Title Large**: 18px, Semi-bold (600)
- **Title Medium**: 16px, Medium (500)
- **Title Small**: 14px, Medium (500)
- **Body Large**: 18px, Normal (increased for readability)
- **Body Medium**: 16px, Normal (increased for readability)
- **Body Small**: 14px, Normal (increased for readability)
- **Label Large**: 14px, Medium (500)
- **Label Medium**: 12px, Medium (500)
- **Label Small**: 11px, Medium (500)

### Letter Spacing
- **Display/Headline**: 0.5px
- **Title**: 0.2-0.3px
- **Body**: 0.1-0.2px
- **Labels**: 0.2-0.5px

### Line Height
- **Display/Headline**: 1.2-1.3
- **Body**: 1.6 (increased for readability)
- **Labels**: 1.4

## Component Specifications

### Buttons
- **Minimum Size**: 120px × 64px (increased for accessibility)
- **Padding**: 40px horizontal, 20px vertical
- **Border Radius**: 16px (rounded corners)
- **Font Size**: 20px (increased for readability)
- **Font Weight**: Semi-bold (600)
- **Elevation**: 2px (4px when pressed)

### Cards
- **Border Radius**: 16px
- **Elevation**: 2px
- **Shadow**: Black at 10% opacity
- **Margin**: 16px horizontal, 12px vertical

### Input Fields
- **Border Radius**: 12px
- **Padding**: 24px horizontal, 20px vertical (increased for accessibility)
- **Font Size**: 18px (increased for readability)
- **Border Width**: 1px (2px when focused)

### Chips
- **Border Radius**: 20px (pill-shaped)
- **Padding**: 12px horizontal, 8px vertical
- **Font Size**: 14px

### Dialogs
- **Border Radius**: 20px
- **Elevation**: 8px

### Snackbars
- **Border Radius**: 12px
- **Behavior**: Floating
- **Background**: Dark Grey-Brown (`#776E67`) with white text

## Accessibility Considerations

- **Contrast Ratios**: All text colors meet WCAG AA standards
- **Primary on White**: 3.5:1 (meets AA for large text)
- **Text Primary on Background Light**: 2.8:1 (meets AA for large text, use with caution for small text)
- **Button Sizes**: Minimum 64px height for touch targets
- **Font Sizes**: Increased from standard to improve readability
- **Line Heights**: Increased to 1.6 for body text

## Color Palette Summary

| Color Name | Hex Code | RGB | Usage |
|------------|----------|-----|-------|
| Primary (Muted Grey-Brown) | `#9A8C84` | `rgb(154, 140, 132)` | Main brand, primary actions |
| Primary Light (Cool Grey-Beige) | `#C2BAB1` | `rgb(194, 186, 177)` | Secondary elements, backgrounds |
| Primary Dark (Dark Grey-Brown) | `#776E67` | `rgb(119, 110, 103)` | Text, dark accents |
| Accent (Warm Tan) | `#D6BF99` | `rgb(214, 191, 153)` | Secondary actions |
| Error Red | `#E74C3C` | `rgb(231, 76, 60)` | Errors, warnings |
| Background Light (Cream Beige) | `#F0E5D5` | `rgb(240, 229, 213)` | Page backgrounds |
| Surface White | `#FFFFFF` | `rgb(255, 255, 255)` | Cards, surfaces |
| Secondary Container | `#E8DDCD` | `rgb(232, 221, 205)` | Secondary containers |

## Implementation Examples

### CSS/SCSS
```css
.primary-button {
  background-color: #9A8C84;
  color: #FFFFFF;
  border-radius: 16px;
  padding: 20px 40px;
  font-size: 20px;
  font-weight: 600;
  min-height: 64px;
}

.secondary-button {
  background-color: #D6BF99;
  color: #FFFFFF;
  border-radius: 16px;
  padding: 20px 40px;
  font-size: 20px;
  font-weight: 600;
  min-height: 64px;
}

.card {
  background-color: #FFFFFF;
  border-radius: 16px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  margin: 12px 16px;
}

.page-background {
  background-color: #F0E5D5;
}

.input-field {
  background-color: #FFFFFF;
  border: 1px solid #C2BAB1;
  border-radius: 12px;
  padding: 20px 24px;
  font-size: 18px;
}

.input-field:focus {
  border: 2px solid #9A8C84;
}
```

### Tailwind CSS (Custom Colors)
```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        'primary': '#9A8C84',
        'primary-light': '#C2BAB1',
        'primary-dark': '#776E67',
        'accent': '#D6BF99',
        'error': '#E74C3C',
        'background-light': '#F0E5D5',
        'surface-white': '#FFFFFF',
        'secondary-container': '#E8DDCD',
        'text-primary': '#776E67',
        'text-secondary': '#9A8C84',
      },
      borderRadius: {
        'card': '16px',
        'input': '12px',
        'chip': '20px',
        'dialog': '20px',
      },
      fontSize: {
        'display-lg': '32px',
        'display-md': '28px',
        'display-sm': '24px',
        'headline-lg': '22px',
        'headline-md': '20px',
        'headline-sm': '18px',
        'body-lg': '18px',
        'body-md': '16px',
        'body-sm': '14px',
      },
      spacing: {
        'button-h': '40px',
        'button-v': '20px',
        'input-h': '24px',
        'input-v': '20px',
      },
    },
  },
}
```

### React/MUI Theme
```javascript
import { createTheme } from '@mui/material/styles';

const theme = createTheme({
  palette: {
    primary: {
      main: '#9A8C84',
      light: '#C2BAB1',
      dark: '#776E67',
      contrastText: '#FFFFFF',
    },
    secondary: {
      main: '#D6BF99',
      light: '#E8DDCD',
      dark: '#B8A585',
      contrastText: '#FFFFFF',
    },
    error: {
      main: '#E74C3C',
    },
    background: {
      default: '#F0E5D5',
      paper: '#FFFFFF',
    },
    text: {
      primary: '#776E67',
      secondary: '#9A8C84',
    },
  },
  typography: {
    fontFamily: 'Roboto, sans-serif',
    h1: { fontSize: '32px', fontWeight: 700, letterSpacing: '0.5px' },
    h2: { fontSize: '28px', fontWeight: 700, letterSpacing: '0.5px' },
    h3: { fontSize: '24px', fontWeight: 600, letterSpacing: '0.5px' },
    h4: { fontSize: '22px', fontWeight: 600, letterSpacing: '0.3px' },
    h5: { fontSize: '20px', fontWeight: 600, letterSpacing: '0.3px' },
    h6: { fontSize: '18px', fontWeight: 600, letterSpacing: '0.3px' },
    body1: { fontSize: '18px', lineHeight: 1.6, letterSpacing: '0.2px' },
    body2: { fontSize: '16px', lineHeight: 1.6, letterSpacing: '0.1px' },
  },
  shape: {
    borderRadius: 16,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          minHeight: '64px',
          padding: '20px 40px',
          fontSize: '20px',
          fontWeight: 600,
          borderRadius: '16px',
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: '16px',
          boxShadow: '0 2px 4px rgba(0, 0, 0, 0.1)',
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          '& .MuiOutlinedInput-root': {
            borderRadius: '12px',
            fontSize: '18px',
            padding: '20px 24px',
          },
        },
      },
    },
  },
});
```

## Visual Reference

For a visual reference of these colors, see the app's theme implementation in:
- Flutter: `lib/theme.dart`
- The colors are used throughout the app in screens, buttons, cards, and other UI components

## Design Principles

1. **Accessibility First**: All colors, sizes, and spacing are optimized for accessibility
2. **Calm and Soothing**: Earth tones create a calm, non-distracting environment
3. **High Contrast**: Text colors provide sufficient contrast for readability
4. **Consistent Spacing**: 16px border radius for cards/buttons, 12px for inputs
5. **Large Touch Targets**: Minimum 64px height for buttons
6. **Readable Typography**: Increased font sizes and line heights for better readability

---

**Last Updated**: Based on current app theme as of the migration to custom pictograms and Cloudinary integration.
