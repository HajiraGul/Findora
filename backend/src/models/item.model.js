const mongoose = require('mongoose');

const itemSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
      minlength: 3,
      maxlength: 120,
    },
    description: {
      type: String,
      required: true,
      trim: true,
      minlength: 20,
      maxlength: 2000,
    },
    category: {
      type: String,
      required: true,
      trim: true,
      maxlength: 80,
    },
    status: {
      type: String,
      enum: ['lost', 'found'],
      required: true,
    },
    color: {
      type: String,
      trim: true,
      default: '',
      maxlength: 40,
    },
    location: {
      address: {
        type: String,
        required: true,
        trim: true,
        maxlength: 240,
      },
      latitude: {
        type: Number,
        min: -90,
        max: 90,
      },
      longitude: {
        type: Number,
        min: -180,
        max: 180,
      },
    },
    images: {
      type: [String],
      default: [],
      validate: {
        validator(images) {
          return images.length <= 4;
        },
        message: 'Maximum 4 images are allowed',
      },
    },
    imagePublicIds: {
      type: [String],
      default: [],
      validate: {
        validator(imagePublicIds) {
          return imagePublicIds.length <= 4;
        },
        message: 'Maximum 4 image public IDs are allowed',
      },
    },
    reward: {
      enabled: {
        type: Boolean,
        default: false,
      },
      amount: {
        type: Number,
        min: 0,
        default: 0,
      },
    },
    handoverMethod: {
      type: String,
      trim: true,
      default: '',
      maxlength: 80,
    },
    contactInfo: {
      type: String,
      trim: true,
      default: '',
      maxlength: 120,
    },
    isResolved: {
      type: Boolean,
      default: false,
    },
    resolvedAt: {
      type: Date,
    },
    postedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

itemSchema.index({
  title: 'text',
  description: 'text',
  category: 'text',
  'location.address': 'text',
});

function getTimeAgo(date) {
  const diffMs = Date.now() - new Date(date).getTime();
  const minutes = Math.max(1, Math.floor(diffMs / (1000 * 60)));

  if (minutes < 60) return `${minutes} min ago`;

  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} hour${hours === 1 ? '' : 's'} ago`;

  const days = Math.floor(hours / 24);
  return `${days} day${days === 1 ? '' : 's'} ago`;
}

itemSchema.methods.toSafeObject = function toSafeObject(distanceKm) {
  const postedBy = this.postedBy;
  const postedByName =
    postedBy && typeof postedBy === 'object' && postedBy.fullName
      ? postedBy.fullName
      : 'Findora User';

  return {
    id: this._id.toString(),
    title: this.title,
    description: this.description,
    category: this.category,
    status: this.status,
    location: this.location.address,
    latitude: this.location.latitude,
    longitude: this.location.longitude,
    postedBy: postedByName,
    postedById:
      postedBy && typeof postedBy === 'object' && postedBy._id
        ? postedBy._id.toString()
        : this.postedBy
        ? this.postedBy.toString()
        : null,
    timeAgo: getTimeAgo(this.createdAt),
    imageUrl: this.images[0] || null,
    images: this.images,
    imagePublicIds: this.imagePublicIds,
    color: this.color || null,
    date: this.createdAt.toISOString().slice(0, 10),
    isResolved: this.isResolved,
    reward: this.reward,
    handoverMethod: this.handoverMethod || null,
    contactInfo: this.contactInfo || null,
    distanceKm,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
    resolvedAt: this.resolvedAt,
  };
};

module.exports = mongoose.model('Item', itemSchema);
