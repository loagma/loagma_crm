import { uploadBase64Image } from './src/services/cloudinaryService.js';

// Test base64 image (1x1 red pixel)
const testBase64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';

console.log('🧪 Testing Cloudinary upload...');

uploadBase64Image(testBase64, 'test')
  .then((url) => {
    console.log('✅ Upload successful!');
    console.log('📸 Image URL:', url);
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Upload failed:', error.message);
    process.exit(1);
  });
