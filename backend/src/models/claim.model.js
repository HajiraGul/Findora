const mongoose = require('mongoose');

const claimAnswerSchema = new mongoose.Schema(
  {
    question: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    answer: {
      type: String,
      required: true,
      trim: true,
      maxlength: 1000,
    },
  },
  { _id: false }
);

const claimSchema = new mongoose.Schema(
  {
    item: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Item',
      required: true,
      index: true,
    },
    claimant: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: 'pending',
      index: true,
    },
    answers: {
      type: [claimAnswerSchema],
      default: [],
    },
    proofType: {
      type: String,
      trim: true,
      maxlength: 80,
    },
    adminNote: {
      type: String,
      trim: true,
      default: '',
      maxlength: 500,
    },
    reviewedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    reviewedAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// One claim per user per item
claimSchema.index({ item: 1, claimant: 1 }, { unique: true });

claimSchema.methods.toSafeObject = function toSafeObject() {
  const populatedItem =
    this.item && typeof this.item === 'object' && this.item._id ? this.item : null;
  const populatedClaimant =
    this.claimant && typeof this.claimant === 'object' && this.claimant._id
      ? this.claimant
      : null;

  return {
    id: this._id.toString(),
    itemId: populatedItem ? populatedItem._id.toString() : this.item.toString(),
    itemTitle: populatedItem ? populatedItem.title : undefined,
    itemCategory: populatedItem ? populatedItem.category : undefined,
    claimantId: populatedClaimant
      ? populatedClaimant._id.toString()
      : this.claimant.toString(),
    claimantName: populatedClaimant ? populatedClaimant.fullName : undefined,
    status: this.status,
    answers: this.answers.map((a) => ({ question: a.question, answer: a.answer })),
    proofType: this.proofType || null,
    adminNote: this.adminNote || null,
    reviewedBy: this.reviewedBy ? this.reviewedBy.toString() : null,
    reviewedAt: this.reviewedAt || null,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

module.exports = mongoose.model('Claim', claimSchema);
