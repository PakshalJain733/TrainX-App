import { Router } from 'express';

const router = Router();

// Current mobile app release info
const CURRENT_APP_VERSION = {
  versionCode: 3,
  versionName: '1.2.0',
  minSupportedVersionCode: 1,
  apkUrl: 'https://train-x-app.vercel.app/TrainX.apk',
  directDownloadUrl: 'https://train-x-app.vercel.app/TrainX.apk',
  releaseNotes: [
    'Super Admin & Admin dedicated role sidebars and navigation',
    'Fixed role leakage across Super Admin, College Admin, Trainer dashboards',
    'Database sync and C2C 2029 batch persistence',
    'Direct In-App OTA Update Checker & One-Tap Installer'
  ],
  forceUpdate: false,
  publishedAt: new Date().toISOString(),
};

router.get('/version', (req, res) => {
  res.json({
    success: true,
    data: CURRENT_APP_VERSION,
  });
});

router.get('/download-apk', (req, res) => {
  res.redirect('https://train-x-app.vercel.app/TrainX.apk');
});

export default router;
