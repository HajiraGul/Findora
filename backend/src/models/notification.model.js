const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    type: {
      type: String,
      enum: ['match', 'claim', 'account', 'system'],
      required: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
      maxlength: 160,
    },
    body: {
      type: String,
      required: true,
      trim: true,
      maxlength: 500,
    },
    // Free-form payload the client uses to deep-link (e.g. { kind: 'match',
    // itemId, matchItemId }). Kept loose so new notification types don't need a
    // schema change.
    data: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    isRead: {
      type: Boolean,
      default: false,
      index: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

notificationSchema.index({ user: 1, createdAt: -1 });

function getTimeAgo(date) {
  const diffMs = Date.now() - new Date(date).getTime();
  const minutes = Math.max(1, Math.floor(diffMs / (1000 * 60)));

  if (minutes < 60) return `${minutes} min ago`;

  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} hour${hours === 1 ? '' : 's'} ago`;

  const days = Math.floor(hours / 24);
  return `${days} day${days === 1 ? '' : 's'} ago`;
}

notificationSchema.methods.toSafeObject = function toSafeObject() {
  return {
    id: this._id.toString(),
    type: this.type,
    title: this.title,
    body: this.body,
    data: this.data || {},
    isRead: this.isRead,
    timeAgo: getTimeAgo(this.createdAt),
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model('Notification', notificationSchema);
