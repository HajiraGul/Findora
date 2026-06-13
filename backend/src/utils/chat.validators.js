function validateMessagePayload(payload) {
  const errors = [];
  const data = {};

  const text = String(payload.text || '').trim();
  if (!text) {
    errors.push('Message text is required');
  } else if (text.length > 2000) {
    errors.push('Message must be at most 2000 characters');
  } else {
    data.text = text;
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
  validateChatStatusPayload,
};
