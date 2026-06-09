const allowedStatuses = ['lost', 'found'];

function validateItemPayload(payload, { partial = false } = {}) {
  const errors = [];
  const data = {};

  assignString(data, errors, payload, 'title', {
    required: !partial,
    min: 3,
    max: 120,
    label: 'Title',
  });
  assignString(data, errors, payload, 'description', {
    required: !partial,
    min: 20,
    max: 2000,
    label: 'Description',
  });
  assignString(data, errors, payload, 'category', {
    required: !partial,
    min: 2,
    max: 80,
    label: 'Category',
  });

  if (Object.prototype.hasOwnProperty.call(payload, 'status') || !partial) {
    const status = String(payload.status || '').trim().toLowerCase();

    if (!status) errors.push('Status is required');
    if (status && !allowedStatuses.includes(status)) {
      errors.push('Status must be lost or found');
    }

    if (status) data.status = status;
  }

  assignString(data, errors, payload, 'color', {
    required: false,
    max: 40,
    label: 'Color',
  });
  assignString(data, errors, payload, 'handoverMethod', {
    required: false,
    max: 80,
    label: 'Handover method',
  });
  assignString(data, errors, payload, 'contactInfo', {
    required: false,
    max: 120,
    label: 'Contact info',
  });

  const location = normalizeLocation(payload.location, payload);
  if (!partial || location.provided) {
    if (!location.address) errors.push('Location address is required');

    data.location = {
      address: location.address,
      ...(location.latitude !== undefined ? { latitude: location.latitude } : {}),
      ...(location.longitude !== undefined
        ? { longitude: location.longitude }
        : {}),
    };
  }

  if (Object.prototype.hasOwnProperty.call(payload, 'reward')) {
    const reward = payload.reward || {};
    const enabled = reward.enabled === true;
    const amount = Number(reward.amount || 0);

    if (Number.isNaN(amount) || amount < 0) {
      errors.push('Reward amount must be a positive number');
    }

    data.reward = {
      enabled,
      amount: enabled ? amount : 0,
    };
  }

  if (Object.prototype.hasOwnProperty.call(payload, 'images')) {
    const { errors: imageErrors, images } = validateImageUrls(payload.images);
    errors.push(...imageErrors);
    data.images = images;
  }

  if (partial && Object.keys(data).length === 0) {
    errors.push('No item fields provided');
  }

  return { errors, data };
}

function validateImagePayload(payload) {
  const imageInput = Object.prototype.hasOwnProperty.call(payload, 'imageUrls')
    ? payload.imageUrls
    : payload.images || payload.imageUrl;
  const { errors, images } = validateImageUrls(imageInput);

  if (images.length === 0) {
    errors.push('At least one image URL is required');
  }

  return { errors, data: { images } };
}

function validateListQuery(query) {
  const filters = {};
  const page = Math.max(1, Number(query.page) || 1);
  const limit = Math.min(50, Math.max(1, Number(query.limit) || 20));

  if (query.status) {
    const status = String(query.status).toLowerCase();
    if (allowedStatuses.includes(status)) filters.status = status;
  }
  if (query.category) filters.category = String(query.category).trim();
  if (query.color) filters.color = String(query.color).trim();
  if (query.q) filters.q = String(query.q).trim();
  if (query.fromDate) filters.fromDate = new Date(query.fromDate);
  if (query.toDate) filters.toDate = new Date(query.toDate);
  if (query.includeResolved !== 'true') filters.isResolved = false;

  return {
    filters,
    page,
    limit,
    sort: String(query.sort || 'newest'),
  };
}

function validateNearbyQuery(query) {
  const latitude = Number(query.lat ?? query.latitude);
  const longitude = Number(query.lng ?? query.longitude);
  const radiusKm = Math.min(100, Math.max(0.1, Number(query.radiusKm) || 1));

  const errors = [];
  if (Number.isNaN(latitude) || latitude < -90 || latitude > 90) {
    errors.push('Valid latitude is required');
  }
  if (Number.isNaN(longitude) || longitude < -180 || longitude > 180) {
    errors.push('Valid longitude is required');
  }

  return {
    errors,
    data: {
      latitude,
      longitude,
      radiusKm,
      status: query.status,
      category: query.category,
      sort: String(query.sort || 'distance'),
    },
  };
}

function assignString(data, errors, payload, key, options) {
  if (!Object.prototype.hasOwnProperty.call(payload, key)) {
    if (options.required) errors.push(`${options.label} is required`);
    return;
  }

  const value = String(payload[key] || '').trim();
  if (!value && options.required) errors.push(`${options.label} is required`);
  if (value && options.min && value.length < options.min) {
    errors.push(`${options.label} must be at least ${options.min} characters`);
  }
  if (value && options.max && value.length > options.max) {
    errors.push(`${options.label} must be at most ${options.max} characters`);
  }

  if (value || Object.prototype.hasOwnProperty.call(payload, key)) {
    data[key] = value;
  }
}

function normalizeLocation(location, payload) {
  const source = location && typeof location === 'object' ? location : {};
  const address = String(source.address || payload.location || '').trim();
  const latitude = parseOptionalNumber(source.latitude ?? payload.latitude);
  const longitude = parseOptionalNumber(source.longitude ?? payload.longitude);

  return {
    provided:
      Boolean(location) ||
      Object.prototype.hasOwnProperty.call(payload, 'location') ||
      Object.prototype.hasOwnProperty.call(payload, 'latitude') ||
      Object.prototype.hasOwnProperty.call(payload, 'longitude'),
    address,
    latitude,
    longitude,
  };
}

function parseOptionalNumber(value) {
  if (value === undefined || value === null || value === '') return undefined;

  const number = Number(value);
  return Number.isNaN(number) ? undefined : number;
}

function validateImageUrls(input) {
  const values = Array.isArray(input) ? input : input ? [input] : [];
  const images = values.map((value) => String(value || '').trim()).filter(Boolean);
  const errors = [];

  if (images.length > 4) errors.push('Maximum 4 images are allowed');

  for (const image of images) {
    if (image.length > 2_000_000) {
      errors.push('Image is too large');
      break;
    }

    if (
      !/^https?:\/\/.+/i.test(image) &&
      !/^data:image\/(png|jpe?g|webp);base64,/i.test(image)
    ) {
      errors.push('Image must be a valid URL or selected image');
      break;
    }
  }

  return {
    errors,
    images: [...new Set(images)].slice(0, 4),
  };
}

module.exports = {
  validateItemPayload,
  validateImagePayload,
  validateListQuery,
  validateNearbyQuery,
};
