# Custom Splash Screen Image Setup Guide

## Image Requirements

To use a custom image for the native splash screen, please provide:

1. **Image Format**: PNG (recommended) or JPG
2. **Image Dimensions**: 
   - **Recommended**: 1080x1920 pixels (9:16 aspect ratio for portrait)
   - **Minimum**: 720x1280 pixels
   - **Maximum**: 1440x2560 pixels
3. **File Size**: Keep under 500KB for fast loading
4. **Background**: The image should include the background (gradient, colors, etc.) as part of the image itself

## Where to Place the Image

### For Android:
1. Place your image file in: `android/app/src/main/res/drawable/`
2. Name it: `splash_image.png` (or `.jpg` if using JPG)
3. The file will be automatically used by the splash screen

### For iOS:
1. Place your image file in: `ios/Runner/Assets.xcassets/`
2. Create a new Image Set named: `SplashImage`
3. Add your image to the Image Set
4. The splash screen will automatically use it

## Alternative: Single Image for Both Platforms

If you provide a single image, I can:
1. Place it in the Android drawable folder
2. Set it up for iOS as well
3. Update both splash screen configurations to use your image

## After Providing the Image

Once you provide the image file, I will:
1. Update `android/app/src/main/res/drawable/launch_background.xml` to use your image
2. Update `ios/Runner/Base.lproj/LaunchScreen.storyboard` to use your image
3. Ensure proper scaling and centering
4. Test that it displays correctly on both platforms

## Current Status

The splash screen is currently using a programmatic design (gradient + shapes). Once you provide the image, I'll replace it with your custom image.
