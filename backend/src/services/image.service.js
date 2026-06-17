const { configureCloudinary } = require('../config/cloudinary');

const CLOUDINARY_HOST_RE = /^https:\/\/res\.cloudinary\.com\/[^/]+\/image\/upload\//i;

async function uploadImages(images = [], folder = 'findora/items') {
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
      folder,
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

function uploadItemImages(images = []) {
  return uploadImages(images, 'findora/items');
}

function uploadClaimImages(images = []) {
  return uploadImages(images, 'findora/claims');
}

// Uploads a single image shared inside a chat conversation and returns its
// hosted URL. Chat photos live in their own Cloudinary folder so they stay
// separate from item/claim media.
async function uploadChatImage(image) {
  const { urls } = await uploadImages(image ? [image] : [], 'findora/chat');
  return urls[0] || null;
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
  uploadImages,
  uploadItemImages,
  uploadClaimImages,
  uploadChatImage,
};
