// A message carries text, an image, or both. Only the combination "no text and
// no image" is rejected, so existing text-only sends behave exactly as before.
function validateMessagePayload(payload) {
  const errors = [];
  const data = { text: '' };

  const text = String(payload.text || '').trim();
  if (text.length > 2000) {
    errors.push('Message must be at most 2000 characters');
  } else {
    data.text = text;
  }

  const imageUrl = String(payload.imageUrl || '').trim();
  if (imageUrl) data.imageUrl = imageUrl;

  if (!data.text && !data.imageUrl) {
    errors.push('Message text or an image is required');
  }

  return { errors, data };
}

function validateChatImagePayload(payload) {
  const errors = [];
  const data = {};

  const image = String(payload.image || '').trim();
  if (!image) {
    errors.push('Image is required');
  } else if (image.length > 2_000_000) {
    errors.push('Image is too large');
  } else if (
    !/^https?:\/\/.+/i.test(image) &&
    !/^data:image\/(png|jpe?g|webp);base64,/i.test(image)
  ) {
    errors.push('Image must be a valid URL or selected image');
  } else {
    data.image = image;
  }

  return { errors, data };
}

function validateChatStatusPayload(payload) {
  const errors = [];
  const data = {};

  if (typeof payload.enabled !== 'boolean') {
    errors.push('enabled must be true or false');
  } else {
    data.enabled = payload.enabled;
  }

  return { errors, data };
}

module.exports = {
  validateMessagePayload,
  validateChatImagePayload,
  validateChatStatusPayload,
};
