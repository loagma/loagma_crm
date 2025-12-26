/**
 * Approval Expiry Background Job
 * 
 * This job runs periodically to expire stale approval requests.
 * Can be triggered via:
 * 1. Cron job (recommended for production)
 * 2. setInterval (for simple deployments)
 * 3. Manual API call to /punch/system/expire-approvals
 */

import { expireStaleApprovals } from '../controllers/punchStatusController.js';

// Run interval in milliseconds (5 minutes)
const EXPIRY_CHECK_INTERVAL = 5 * 60 * 1000;

let intervalId = null;

/**
 * Start the expiry job using setInterval
 * Use this for simple deployments without cron
 */
export function startExpiryJob() {
    if (intervalId) {
        console.log('⚠️ Expiry job already running');
        return;
    }

    console.log('🕐 Starting approval expiry job (every 5 minutes)');

    // Run immediately on start
    expireStaleApprovals().then(result => {
        if (result.expiredCount > 0) {
            console.log(`🕐 Initial cleanup: expired ${result.expiredCount} approvals`);
        }
    });

    // Then run every 5 minutes
    intervalId = setInterval(async () => {
        const result = await expireStaleApprovals();
        if (result.expiredCount > 0) {
            console.log(`🕐 Expired ${result.expiredCount} stale approvals`);
        }
    }, EXPIRY_CHECK_INTERVAL);
}

/**
 * Stop the expiry job
 */
export function stopExpiryJob() {
    if (intervalId) {
        clearInterval(intervalId);
        intervalId = null;
        console.log('🛑 Approval expiry job stopped');
    }
}

export default { startExpiryJob, stopExpiryJob };
