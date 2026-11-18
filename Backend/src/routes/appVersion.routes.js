import { Router } from 'express';

const router = Router();

// Current mobile app release info
const CURRENT_APP_VERSION = {
  versionCode: 2,
  versionName: '1.1.0',
  minSupportedVersionCode: 1,
  apkUrl: 'https://train-x-app.vercel.app/TrainX.apk',
  directDownloadUrl: 'https://train-x-app.vercel.app/TrainX.apk',
  releaseNotes: [
    'Super Admin Mobile Command Center (Live Server Health, Colleges Directory, User Controls)',
    'College Admin Portal (Batches, Approvals, Analytics)',
    'Trainer & Mentor Workspace',
    'Direct In-App OTA Update Checker & One-Tap Installer',
    'Zero-database Super Admin instant login bypass'
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
