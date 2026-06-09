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
      required: true,
      unique: true,
      trim: true,
      maxlength: 20,
    },
    cityOrUniversity: {
      type: String,
      required: true,
      trim: true,
      maxlength: 120,
    },
    password: {
      type: String,
      required: true,
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
    phone: this.phone,
    cityOrUniversity: this.cityOrUniversity,
    role: this.role,
    isEmailVerified: this.isEmailVerified,
    avatarUrl: this.avatarUrl,
    preferences: {
      notifications: this.preferences?.notifications ?? true,
      darkMode: this.preferences?.darkMode ?? false,
      twoFactor: this.preferences?.twoFactor ?? false,
      biometric: this.preferences?.biometric ?? false,
    },
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

module.exports = mongoose.model('User', userSchema);
