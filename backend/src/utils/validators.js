function isValidEmail(email) {
  return /^[\w.-]+@([\w-]+\.)+[\w-]{2,}$/.test(email);
}

function normalizePhone(phone) {
  return String(phone || '').replace(/\s+/g, '');
}

function isValidPhone(phone) {
  return /^\+?[0-9]{10,13}$/.test(normalizePhone(phone));
}

function hasUppercase(value) {
  return /[A-Z]/.test(value);
}

function hasDigit(value) {
  return /[0-9]/.test(value);
}

function validateRegisterPayload(payload) {
  const errors = [];
  const fullName = String(payload.fullName || '').trim();
  const email = String(payload.email || '').trim().toLowerCase();
  const phone = normalizePhone(payload.phone);
  const cityOrUniversity = String(
    payload.cityOrUniversity || payload.city || ''
  ).trim();
  const password = String(payload.password || '');

  if (!fullName) errors.push('Full name is required');
  if (fullName && fullName.length < 3) {
    errors.push('Name must be at least 3 characters');
  }

  if (!email) errors.push('Email is required');
  if (email && !isValidEmail(email)) errors.push('Enter a valid email address');

  if (!phone) errors.push('Phone number is required');
  if (phone && !isValidPhone(phone)) {
    errors.push('Enter a valid phone number');
  }

  if (!cityOrUniversity) errors.push('City or university is required');
  if (cityOrUniversity && cityOrUniversity.length < 2) {
    errors.push('Please enter a valid city or university');
  }

  if (!password) errors.push('Password is required');
  if (password && password.length < 8) {
    errors.push('Password must be at least 8 characters');
  }
  if (password && !hasUppercase(password)) {
    errors.push('Password must contain at least 1 uppercase letter');
  }
  if (password && !hasDigit(password)) {
    errors.push('Password must contain at least 1 number');
  }

  return {
    errors,
    data: {
      fullName,
      email,
      phone,
      cityOrUniversity,
      password,
    },
  };
}

function validateLoginPayload(payload) {
  const errors = [];
  const email = String(payload.email || '').trim().toLowerCase();
  const password = String(payload.password || '');

  if (!email) errors.push('Email is required');
  if (email && !isValidEmail(email)) errors.push('Enter a valid email address');
  if (!password) errors.push('Password is required');

  return {
    errors,
    data: {
      email,
      password,
    },
  };
}

function validateEmailPayload(payload) {
  const errors = [];
  const email = String(payload.email || '').trim().toLowerCase();

  if (!email) errors.push('Email is required');
  if (email && !isValidEmail(email)) errors.push('Enter a valid email address');

  return {
    errors,
    data: { email },
  };
}

function validateOtpPayload(payload) {
  const { errors, data } = validateEmailPayload(payload);
  const otp = String(payload.otp || '').trim();

  if (!otp) errors.push('OTP is required');
  if (otp && !/^[0-9]{6}$/.test(otp)) {
    errors.push('OTP must be a 6-digit code');
  }

  return {
    errors,
    data: {
      ...data,
      otp,
    },
  };
}

function validateResetPasswordPayload(payload) {
  const { errors, data } = validateOtpPayload(payload);
  const password = String(payload.password || payload.newPassword || '');

  if (!password) errors.push('New password is required');
  if (password && password.length < 8) {
    errors.push('Password must be at least 8 characters');
  }
  if (password && !hasUppercase(password)) {
    errors.push('Password must contain at least 1 uppercase letter');
  }
  if (password && !hasDigit(password)) {
    errors.push('Password must contain at least 1 number');
  }

  return {
    errors,
    data: {
      ...data,
      password,
    },
  };
}

function validateUpdateProfilePayload(payload) {
  const errors = [];
  const data = {};

  if (Object.prototype.hasOwnProperty.call(payload, 'fullName')) {
    const fullName = String(payload.fullName || '').trim();

    if (!fullName) errors.push('Full name cannot be empty');
    if (fullName && fullName.length < 3) {
      errors.push('Name must be at least 3 characters');
    }

    data.fullName = fullName;
  }

  if (Object.prototype.hasOwnProperty.call(payload, 'email')) {
    const email = String(payload.email || '').trim().toLowerCase();

    if (!email) errors.push('Email cannot be empty');
    if (email && !isValidEmail(email)) errors.push('Enter a valid email address');

    data.email = email;
  }

  if (Object.prototype.hasOwnProperty.call(payload, 'phone')) {
    const phone = normalizePhone(payload.phone);

    if (!phone) errors.push('Phone number cannot be empty');
    if (phone && !isValidPhone(phone)) {
      errors.push('Enter a valid phone number');
    }

    data.phone = phone;
  }

  if (
    Object.prototype.hasOwnProperty.call(payload, 'cityOrUniversity') ||
    Object.prototype.hasOwnProperty.call(payload, 'city') ||
    Object.prototype.hasOwnProperty.call(payload, 'university')
  ) {
    const cityOrUniversity = String(
      payload.cityOrUniversity || payload.city || payload.university || ''
    ).trim();

    if (!cityOrUniversity) errors.push('City or university cannot be empty');
    if (cityOrUniversity && cityOrUniversity.length < 2) {
      errors.push('Please enter a valid city or university');
    }

    data.cityOrUniversity = cityOrUniversity;
  }

  if (Object.keys(data).length === 0) {
    errors.push('No profile fields provided');
  }

  return { errors, data };
}

function validateAvatarPayload(payload) {
  const errors = [];
  const avatarUrl = String(payload.avatarUrl || '').trim();

  if (!avatarUrl) errors.push('Avatar URL is required');
  if (avatarUrl && avatarUrl.length > 2_000_000) {
    errors.push('Avatar image is too large');
  }
  if (
    avatarUrl &&
    !/^https?:\/\/.+/i.test(avatarUrl) &&
    !/^data:image\/(png|jpe?g|webp);base64,/i.test(avatarUrl)
  ) {
    errors.push('Avatar must be a valid image URL or selected image');
  }

  return {
    errors,
    data: { avatarUrl },
  };
}

function validatePasswordChangePayload(payload) {
  const errors = [];
  const currentPassword = String(payload.currentPassword || '');
  const newPassword = String(payload.newPassword || payload.password || '');

  if (!currentPassword) errors.push('Current password is required');
  if (!newPassword) errors.push('New password is required');
  if (newPassword && newPassword.length < 8) {
    errors.push('Password must be at least 8 characters');
  }
  if (newPassword && !hasUppercase(newPassword)) {
    errors.push('Password must contain at least 1 uppercase letter');
  }
  if (newPassword && !hasDigit(newPassword)) {
    errors.push('Password must contain at least 1 number');
  }

  return {
    errors,
    data: {
      currentPassword,
      newPassword,
    },
  };
}

function validatePreferencesPayload(payload) {
  const allowedKeys = ['notifications', 'darkMode', 'twoFactor', 'biometric'];
  const errors = [];
  const data = {};

  for (const key of allowedKeys) {
    if (Object.prototype.hasOwnProperty.call(payload, key)) {
      if (typeof payload[key] !== 'boolean') {
        errors.push(`${key} must be a boolean`);
      } else {
        data[key] = payload[key];
      }
    }
  }

  if (Object.keys(data).length === 0) {
    errors.push('No preference fields provided');
  }

  return { errors, data };
}

module.exports = {
  validateRegisterPayload,
  validateLoginPayload,
  validateEmailPayload,
  validateOtpPayload,
  validateResetPasswordPayload,
  validateUpdateProfilePayload,
  validateAvatarPayload,
  validatePasswordChangePayload,
  validatePreferencesPayload,
};
