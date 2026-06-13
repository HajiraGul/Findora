const {
  validateItemPayload,
  validateImagePayload,
  validateListQuery,
  validateNearbyQuery,
} = require('../utils/item.validators');
const {
  listItems,
  listMyItems,
  getItemById,
  createItem,
  updateItem,
  deleteItem,
  resolveItem,
  addItemImages,
  listNearbyItems,
} = require('../services/item.service');
const { getMatchesForItem } = require('../services/match.service');
const { notifyOwnerOfMatch } = require('../services/notification.service');

async function index(req, res, next) {
  try {
    const options = validateListQuery(req.query);
    const result = await listItems(options);

    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

async function mine(req, res, next) {
  try {
    const options = validateListQuery(req.query);

    if (req.query.includeResolved !== 'false') {
      delete options.filters.isResolved;
    }

    const result = await listMyItems(req.user._id, options);

    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

async function nearby(req, res, next) {
  try {
    const { errors, data } = validateNearbyQuery(req.query);

    if (errors.length > 0) {
      return res.status(400).json({
        message: 'Validation failed',
        errors,
      });
    }

    const result = await listNearbyItems(data);

    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

async function show(req, res, next) {
  try {
    const item = await getItemById(req.params.id);

    return res.status(200).json({ item });
  } catch (error) {
    return next(error);
  }
}

async function store(req, res, next) {
  try {
    const { errors, data } = validateItemPayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({
        message: 'Validation failed',
        errors,
      });
    }

    const item = await createItem(req.user._id, data);

    return res.status(201).json({
      message: 'Item created successfully',
      item,
    });
  } catch (error) {
    return next(error);
  }
}

async function patch(req, res, next) {
  try {
    const { errors, data } = validateItemPayload(req.body, { partial: true });

    if (errors.length > 0) {
      return res.status(400).json({
        message: 'Validation failed',
        errors,
      });
    }

    const item = await updateItem(req.params.id, req.user, data);

    return res.status(200).json({
      message: 'Item updated successfully',
      item,
    });
  } catch (error) {
    return next(error);
  }
}

async function destroy(req, res, next) {
  try {
    await deleteItem(req.params.id, req.user);

    return res.status(200).json({
      message: 'Item deleted successfully',
    });
  } catch (error) {
    return next(error);
  }
}

async function resolve(req, res, next) {
  try {
    const item = await resolveItem(req.params.id, req.user);

    return res.status(200).json({
      message: 'Item resolved successfully',
      item,
    });
  } catch (error) {
    return next(error);
  }
}

async function images(req, res, next) {
  try {
    const { errors, data } = validateImagePayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({
        message: 'Validation failed',
        errors,
      });
    }

    const item = await addItemImages(req.params.id, req.user, data.images);

    return res.status(200).json({
      message: 'Item images updated successfully',
      item,
    });
  } catch (error) {
    return next(error);
  }
}

async function matches(req, res, next) {
  try {
    const result = await getMatchesForItem(req.params.id, req.user);

    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
}

async function notifyMatch(req, res, next) {
  try {
    const result = await notifyOwnerOfMatch(
      req.user,
      req.params.id,
      req.body.matchItemId
    );

    return res.status(200).json({
      message: 'Owner notified successfully',
      ...result,
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  index,
  mine,
  nearby,
  show,
  store,
  patch,
  destroy,
  resolve,
  images,
  matches,
  notifyMatch,
};
