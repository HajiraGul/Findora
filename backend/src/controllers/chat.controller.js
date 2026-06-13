const {
  validateMessagePayload,
  validateChatStatusPayload,
} = require('../utils/chat.validators');
const {
  ensureChatForClaim,
  getMyChats,
  getChatById,
  listMessages,
  sendMessage,
  listAllChats,
  setChatEnabled,
} = require('../services/chat.service');

async function mine(req, res, next) {
  try {
    const chats = await getMyChats(req.user);

    return res.status(200).json({ chats, total: chats.length });
  } catch (error) {
    return next(error);
  }
}

async function show(req, res, next) {
  try {
    const chat = await getChatById(req.params.chatId, req.user);

    return res.status(200).json({ chat });
  } catch (error) {
    return next(error);
  }
}

async function messages(req, res, next) {
  try {
    const afterMs = Number(req.query.after) || 0;
    const result = await listMessages(req.params.chatId, req.user, afterMs);

    return res.status(200).json({
      chat: result.chat,
      messages: result.messages,
    });
  } catch (error) {
    return next(error);
  }
}

async function send(req, res, next) {
  try {
    const { errors, data } = validateMessagePayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({ message: 'Validation failed', errors });
    }

    const message = await sendMessage(req.params.chatId, req.user, data.text);

    return res.status(201).json({
      message: 'Message sent',
      chatMessage: message,
    });
  } catch (error) {
    return next(error);
  }
}

async function adminIndex(req, res, next) {
  try {
    const chats = await listAllChats();

    return res.status(200).json({ chats, total: chats.length });
  } catch (error) {
    return next(error);
  }
}

async function adminSetStatus(req, res, next) {
  try {
    const { errors, data } = validateChatStatusPayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({ message: 'Validation failed', errors });
    }

    const chat = await setChatEnabled(req.params.chatId, data.enabled);

    return res.status(200).json({
      message: data.enabled ? 'Chat enabled' : 'Chat disabled',
      chat,
    });
  } catch (error) {
    return next(error);
  }
}

async function adminUnlockForClaim(req, res, next) {
  try {
    const chat = await ensureChatForClaim(req.params.claimId);

    return res.status(200).json({
      message: 'Chat unlocked between claimant and item poster',
      chat,
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  mine,
  show,
  messages,
  send,
  adminIndex,
  adminSetStatus,
  adminUnlockForClaim,
};
