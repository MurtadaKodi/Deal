
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.notifySellerOnNewMessage = onDocumentCreated(
  {
    document: "chats/{chatId}/messages/{messageId}",
    region: "us-central1",
    retry: false,
  },
  async (event) => {
    const message = event.data?.data();
    if (!message || message.isFromBuyer !== true) return;

    const { chatId, messageId } = event.params;
    const db = getFirestore();

    const chatSnapshot = await db.collection("chats").doc(chatId).get();

    if (!chatSnapshot.exists) {
      logger.warn("Chat not found", { chatId });
      return;
    }

    const chat = chatSnapshot.data();
    const sellerId = chat?.sellerId;

    if (
      !sellerId ||
      !chat?.buyerId ||
      message.senderId !== chat.buyerId ||
      sellerId === message.senderId
    ) {
      logger.warn("Invalid message sender", { chatId });
      return;
    }

    // منع معالجة الحدث نفسه أكثر من مرة
    const notificationRef = db
      .collection("notificationDispatches")
      .doc(`${chatId}_${messageId}`);

    try {
      await notificationRef.create({
        chatId,
        messageId,
        sellerId,
        status: "processing",
        createdAt: FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (error.code === 6 || error.code === "already-exists") {
        logger.info("Notification already claimed", { chatId, messageId });
        return;
      }
      throw error;
    }

    try {
      const tokensSnapshot = await db
        .collection("users")
        .doc(sellerId)
        .collection("fcmTokens")
        .get();

      const tokenDocs = tokensSnapshot.docs.filter(
        (doc) =>
          typeof doc.data().token === "string" &&
          doc.data().token.length > 0
      );

      const tokens = [
        ...new Set(tokenDocs.map((doc) => doc.data().token)),
      ];

      if (tokens.length === 0) {
        await notificationRef.update({
          status: "no_devices",
          completedAt: FieldValue.serverTimestamp(),
        });

        logger.info("Seller has no registered devices", { chatId });
        return;
      }

      let successCount = 0;
      let failureCount = 0;
      const invalidTokens = new Set();

      // FCM يدعم حتى 500 رمز لكل طلب
      for (let i = 0; i < tokens.length; i += 500) {
        const batchTokens = tokens.slice(i, i + 500);

        const response = await getMessaging().sendEachForMulticast({
          tokens: batchTokens,
          notification: {
            title: "Deal - رسالة جديدة",
            body: "لديك رسالة جديدة من أحد المشترين",
          },
          data: {
            type: "chat",
            chatId,
          },
          android: {
            priority: "high",
          },
        });

        successCount += response.successCount;
        failureCount += response.failureCount;

        response.responses.forEach((result, index) => {
          if (
            !result.success &&
            result.error?.code ===
              "messaging/registration-token-not-registered"
          ) {
            invalidTokens.add(batchTokens[index]);
          }
        });
      }

      await notificationRef.update({
        status:
          failureCount === 0
            ? "sent"
            : successCount > 0
              ? "partial"
              : "failed",
        successCount,
        failureCount,
        completedAt: FieldValue.serverTimestamp(),
      });

      // حذف الرموز التي أكد FCM انتهاء صلاحيتها
      const invalidDocs = tokenDocs.filter((doc) =>
        invalidTokens.has(doc.data().token)
      );

      for (let i = 0; i < invalidDocs.length; i += 500) {
        const batch = db.batch();

        for (const doc of invalidDocs.slice(i, i + 500)) {
          batch.delete(doc.ref);
        }

        await batch.commit();
      }

      logger.info("Seller notification completed", {
        chatId,
        messageId,
        successCount,
        failureCount,
      });
    } catch (error) {
      logger.error("Seller notification failed", {
        chatId,
        messageId,
        error: String(error),
      });

      await notificationRef.update({
        status: "failed",
        completedAt: FieldValue.serverTimestamp(),
      });

      throw error;
    }
  }
);
