/**
 * Timezone utility for Indian Standard Time (IST) handling
 * IST = UTC +05:30 (no DST)
 */

// IST offset in milliseconds
const IST_OFFSET = 5.5 * 60 * 60 * 1000;

/**
 * Get current IST time (as Date object of the IST instant)
 * @returns {Date}
 */
export function getCurrentISTTime() {
    const nowUTC = Date.now();
    return new Date(nowUTC + IST_OFFSET);
}

/**
 * Convert a UTC date to IST (using fixed offset)
 * @param {Date|string|number} utcDate
 * @returns {Date|null}
 */
export function convertUTCToIST(utcDate) {
    if (!utcDate) return null;
    const d = new Date(utcDate);
    return new Date(d.getTime() + IST_OFFSET);
}

/**
 * Convert an IST date to UTC
 * @param {Date|string|number} istDate
 * @returns {Date|null}
 */
export function convertISTToUTC(istDate) {
    if (!istDate) return null;
    const d = new Date(istDate);
    return new Date(d.getTime() - IST_OFFSET);
}

/**
 * Get IST day range (start & end) as UTC instants for DB queries.
 * @param {Date|string|number|null} date 
 * @returns {{ startOfDay: Date, endOfDay: Date }}
 */
export function getISTDateRange(date = null) {
    const baseIST = date ? convertUTCToIST(date) : getCurrentISTTime();

    const startIST = new Date(baseIST);
    startIST.setHours(0, 0, 0, 0);

    const endIST = new Date(baseIST);
    endIST.setHours(23, 59, 59, 999);

    return {
        startOfDay: convertISTToUTC(startIST),
        endOfDay: convertISTToUTC(endIST)
    };
}

/**
 * Format date in IST using Intl API (correct method)
 * @param {Date|string|number} date
 * @param {'time'|'date'|'datetime'} format
 * @returns {string|null}
 */
export function formatISTTime(date, format = 'datetime') {
    if (!date) return null;

    const d = new Date(date);

    const base = { timeZone: 'Asia/Kolkata', hour12: true };

    switch (format) {
        case 'time':
            return new Intl.DateTimeFormat('en-IN', {
                ...base,
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit'
            }).format(d);

        case 'date':
            return new Intl.DateTimeFormat('en-IN', {
                ...base,
                year: 'numeric',
                month: '2-digit',
                day: '2-digit'
            }).format(d);

        case 'datetime':
        default:
            return new Intl.DateTimeFormat('en-IN', {
                ...base,
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit'
            }).format(d);
    }
}

/**
 * Get IST timestamp in ISO-like format (correct local IST output)
 * ISO standard uses UTC only, so we manually format IST timestamp.
 * @param {Date|string|number|null} date
 * @returns {string}
 */
export function getISTTimestamp(date = null) {
    const d = date ? new Date(date) : new Date();

    // Format in ISO-like but in IST timezone
    const formatted = new Intl.DateTimeFormat('sv-SE', {
        timeZone: 'Asia/Kolkata',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    }).format(d);

    // Convert “YYYY-MM-DD HH:mm:ss” → “YYYY-MM-DDTHH:mm:ss”
    return formatted.replace(' ', 'T');
}

/**
 * Calculate work hours between two UTC instants
 * @param {Date|string|number} startTime 
 * @param {Date|string|number} endTime 
 * @returns {number}
 */
export function calculateWorkHoursIST(startTime, endTime) {
    if (!startTime || !endTime) return 0;

    const s = new Date(startTime);
    const e = new Date(endTime);

    if (isNaN(s) || isNaN(e)) return 0;

    const diffMs = e.getTime() - s.getTime();
    const hours = diffMs / (1000 * 60 * 60);

    return Math.max(0, Math.round(hours * 100) / 100);
}

/**
 * Calculate current active work duration for attendance
 * @param {Date|string|number} punchInTime - UTC instant
 * @returns {number}
 */
export function getCurrentWorkDurationIST(punchInTime) {
    if (!punchInTime) return 0;
    const now = new Date(); // UTC
    return calculateWorkHoursIST(punchInTime, now);
}

/**
 * Check if a UTC instant falls into IST business hours
 * @param {Date|string|number} time
 * @param {number} startHour 
 * @param {number} endHour 
 * @returns {boolean}
 */
export function isWithinBusinessHours(time, startHour = 9, endHour = 18) {
    if (!time) return false;

    const parts = new Intl.DateTimeFormat('en-US', {
        timeZone: 'Asia/Kolkata',
        hour12: false,
        hour: '2-digit'
    }).formatToParts(new Date(time));

    const hour = parseInt(parts.find(p => p.type === 'hour').value, 10);

    return hour >= startHour && hour < endHour;
}

/**
 * IST Timezone metadata
 */
export function getISTTimezoneInfo() {
    return {
        name: "India Standard Time",
        abbreviation: "IST",
        offset: "+05:30",
        offsetMinutes: 330,
        offsetMs: IST_OFFSET
    };
}

export default {
    getCurrentISTTime,
    convertUTCToIST,
    convertISTToUTC,
    getISTDateRange,
    formatISTTime,
    getISTTimestamp,
    calculateWorkHoursIST,
    getCurrentWorkDurationIST,
    isWithinBusinessHours,
    getISTTimezoneInfo
};
