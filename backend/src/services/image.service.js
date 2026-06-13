const { configureCloudinary } = require('../config/cloudinary');

const CLOUDINARY_HOST_RE = /^https:\/\/res\.cloudinary\.com\/[^/]+\/image\/upload\//i;

async function uploadItemImages(images = []) {
  if (!Array.isArray(images) || images.length === 0) {
    return { urls: [], publicIds: [] };
  }

  const cloudinary = configureCloudinary();
  const uploaded = [];

  for (const image of images.slice(0, 4)) {
    const source = String(image || '').trim();
    if (!source) continue;

    if (CLOUDINARY_HOST_RE.test(source)) {
      uploaded.push({
        url: source,
        publicId: publicIdFromCloudinaryUrl(source),
      });
      continue;
    }

    const result = await cloudinary.uploader.upload(source, {
      folder: 'findora/items',
      resource_type: 'image',
      overwrite: false,
    });

    uploaded.push({
      url: result.secure_url,
      publicId: result.public_id,
    });
  }

  return {
    urls: uploaded.map((image) => image.url).filter(Boolean),
    publicIds: uploaded.map((image) => image.publicId).filter(Boolean),
  };
}

function publicIdFromCloudinaryUrl(url) {
  try {
    const parsed = new URL(url);
    const uploadIndex = parsed.pathname.indexOf('/upload/');
    if (uploadIndex === -1) return null;

    const afterUpload = parsed.pathname.slice(uploadIndex + '/upload/'.length);
    const withoutVersion = afterUpload.replace(/^v\d+\//, '');
    return withoutVersion.replace(/\.[^.]+$/, '');
  } catch (_) {
    return null;
  }
}

module.exports = {
  uploadItemImages,
};
