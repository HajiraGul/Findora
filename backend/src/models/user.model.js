const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: true,
      trim: true,
      minlength: 3,
      maxlength: 80,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      lowercase: true,
      maxlength: 120,
    },
    phone: {
      type: String,
      // Optional: Google sign-in users have no phone. `sparse` lets the unique
      // index ignore documents that omit the field, so multiple Google users
      // (all phone-less) don't collide on a single null value.
      unique: true,
      sparse: true,
      trim: true,
      maxlength: 20,
    },
    cityOrUniversity: {
      type: String,
      required: true,
      trim: true,
      maxlength: 120,
    },
    // How this account authenticates. 'google' users sign in via the Google
    // provider and have no password; 'local' users use email + password.
    provider: {
      type: String,
      enum: ['local', 'google'],
      default: 'local',
    },
    googleId: {
      type: String,
      unique: true,
      sparse: true,
      select: false,
    },
    password: {
      type: String,
      // Required only for local (email/password) accounts; Google users have
      // no password.
      required: function requirePassword() {
        return this.provider !== 'google';
      },
      minlength: 8,
      select: false,
    },
    role: {
      type: String,
      enum: ['user', 'admin'],
      default: 'user',
    },
    avatarUrl: {
      type: String,
      trim: true,
      default: '',
      maxlength: 2000000,
    },
    about: {
      type: String,
      trim: true,
      default:
        'Software Engineering student passionate about building secure and helpful digital solutions for campus communities.',
      maxlength: 500,
    },
    preferences: {
      notifications: {
        type: Boolean,
        default: true,
      },
      darkMode: {
        type: Boolean,
        default: false,
      },
      twoFactor: {
        type: Boolean,
        default: false,
      },
      biometric: {
        type: Boolean,
        default: false,
      },
    },
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    tokenVersion: {
      type: Number,
      default: 0,
      select: false,
    },
    emailVerificationOtpHash: {
      type: String,
      select: false,
    },
    emailVerificationOtpExpiresAt: {
      type: Date,
      select: false,
    },
    passwordResetOtpHash: {
      type: String,
      select: false,
    },
    passwordResetOtpExpiresAt: {
      type: Date,
      select: false,
    },
    banned: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

userSchema.methods.toSafeObject = function toSafeObject() {
  return {
    id: this._id.toString(),
    fullName: this.fullName,
    email: this.email,
    phone: this.phone || '',
    cityOrUniversity: this.cityOrUniversity,
    provider: this.provider || 'local',
    role: this.role,
    isEmailVerified: this.isEmailVerified,
    avatarUrl: this.avatarUrl,
    about:
      this.about ||
      'Software Engineering student passionate about building secure and helpful digital solutions for campus communities.',
    preferences: {
      notifications: this.preferences?.notifications ?? true,
      darkMode: this.preferences?.darkMode ?? false,
      twoFactor: this.preferences?.twoFactor ?? false,
      biometric: this.preferences?.biometric ?? false,
    },
    banned: this.banned ?? false,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

module.exports = mongoose.model('User', userSchema);
