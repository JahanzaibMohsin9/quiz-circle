const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Send push notification when announcement is created
 * Triggers on: New document created in 'announcements' collection
 */
exports.sendAnnouncementNotification = functions.firestore
    .document('announcements/{announcementId}')
    .onCreate(async (snap, context) => {
        const announcement = snap.data();

        // Prepare the notification message
        const message = {
            topic: 'announcements',
            notification: {
                title: `📢 ${announcement.title}`,
                body: announcement.message.length > 100
                    ? `${announcement.message.substring(0, 100)}...`
                    : announcement.message
            },
            data: {
                type: 'announcement',
                announcementId: context.params.announcementId,
                actionUrl: '/student/announcements',
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            android: {
                priority: 'high',
                notification: {
                    sound: 'default',
                    color: '#FF6B35',
                    channelId: 'quiz_app_notifications',
                    icon: '@mipmap/ic_launcher'
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                        contentAvailable: true
                    }
                }
            }
        };

        try {
            const response = await admin.messaging().send(message);
            console.log('Announcement notification sent successfully:', response);
            return { success: true, messageId: response };
        } catch (error) {
            console.error('Error sending announcement notification:', error);
            throw new functions.https.HttpsError('internal', 'Failed to send notification');
        }
    });

/**
 * Send push notification when quiz is published
 * Triggers on: Quiz document created with isPublic = true
 */
exports.sendQuizNotification = functions.firestore
    .document('quizzes/{quizId}')
    .onCreate(async (snap, context) => {
        const quiz = snap.data();

        // Only send notification if quiz is public
        if (!quiz.isPublic) {
            console.log('Quiz is not public, skipping notification');
            return null;
        }

        // Prepare the notification message
        const message = {
            topic: 'students',
            notification: {
                title: '📝 New Quiz Available',
                body: `A new quiz "${quiz.title}" has been published. Take it now!`
            },
            data: {
                type: 'quiz',
                quizId: context.params.quizId,
                quizTitle: quiz.title,
                actionUrl: '/student/quizzes',
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            android: {
                priority: 'high',
                notification: {
                    sound: 'default',
                    color: '#FF6B35',
                    channelId: 'quiz_app_notifications',
                    icon: '@mipmap/ic_launcher'
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                        contentAvailable: true
                    }
                }
            }
        };

        try {
            const response = await admin.messaging().send(message);
            console.log('Quiz notification sent successfully:', response);
            return { success: true, messageId: response };
        } catch (error) {
            console.error('Error sending quiz notification:', error);
            throw new functions.https.HttpsError('internal', 'Failed to send notification');
        }
    });

/**
 * Send push notification when quiz is updated to public
 * Triggers on: Quiz document updated to isPublic = true
 */
exports.sendQuizUpdateNotification = functions.firestore
    .document('quizzes/{quizId}')
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const oldData = change.before.data();

        // Only send notification if quiz was just made public
        if (!oldData.isPublic && newData.isPublic) {
            const message = {
                topic: 'students',
                notification: {
                    title: '📝 New Quiz Available',
                    body: `A new quiz "${newData.title}" has been published. Take it now!`
                },
                data: {
                    type: 'quiz',
                    quizId: context.params.quizId,
                    quizTitle: newData.title,
                    actionUrl: '/student/quizzes',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK'
                },
                android: {
                    priority: 'high',
                    notification: {
                        sound: 'default',
                        color: '#FF6B35',
                        channelId: 'quiz_app_notifications'
                    }
                }
            };

            try {
                const response = await admin.messaging().send(message);
                console.log('Quiz update notification sent successfully:', response);
                return { success: true, messageId: response };
            } catch (error) {
                console.error('Error sending quiz update notification:', error);
                throw new functions.https.HttpsError('internal', 'Failed to send notification');
            }
        }

        console.log('Quiz not made public, skipping notification');
        return null;
    });

/**
 * Optional: Clean up old notifications (runs daily)
 * This helps keep the database clean by removing read notifications older than 30 days
 */
exports.cleanupOldNotifications = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
        const db = admin.firestore();
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        try {
            // Find old read notifications
            const snapshot = await db.collection('notifications')
                .where('isRead', '==', true)
                .where('timestamp', '<', thirtyDaysAgo)
                .get();

            if (snapshot.empty) {
                console.log('No old notifications to clean up');
                return null;
            }

            // Delete in batches
            const batch = db.batch();
            snapshot.docs.forEach(doc => {
                batch.delete(doc.ref);
            });

            await batch.commit();
            console.log(`Cleaned up ${snapshot.size} old notifications`);
            return { deleted: snapshot.size };
        } catch (error) {
            console.error('Error cleaning up notifications:', error);
            throw new functions.https.HttpsError('internal', 'Failed to clean up notifications');
        }
    });
