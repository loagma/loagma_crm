/**
 * Timezone utility for Indian Standard Time (IST) handling
 * IST = UTC +05:30 (no DST)
 * 
 * IMPORTANT: All times in the database are stored in UTC.
 * IST conversion is only for display purposes.
 */

// IST offset in milliseconds
const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;

/**
 * Get current time as a Date object (in UTC, as JavaScript Date always is)
 * This is the actual current moment, suitable for storing in database
 * @returns {Date}
 */
export function getCurrentISTTime() {
    // Return current UTC time - JavaScript Date is always UTC internally
    const now = new Date();
    
    console.log('🕐 getCurrentISTTime called:', {
        utcTime: now.toISOString(),
        istFormatted: formatISTTime(now, 'datetime'),
        offset: '+05:30'
    });

    return now;
}

/**
 * Convert a UTC date to IST for display purposes
 * Note: This returns a Date object shifted by IST offset for display
 * @param {Date|string|number} utcDate
 * @returns {Date|null}
 */
export function convertUTCToIST(utcDate) {
    if (!utcDate) return null;
    const d = new Date(utcDate);
    // For display purposes, shift the time by IST offset
    return new Date(d.getTime() + IST_OFFSET_MS);
}

/**
 * Convert an IST-shifted date back to UTC
 * @param {Date|string|number} istDate
 * @returns {Date|null}
 */
export function convertISTToUTC(istDate) {
    if (!istDate) return null;
    const d = new Date(istDate);
    return new Date(d.getTime() - IST_OFFSET_MS);
}

/**
 * Get IST day range (start & end) as UTC instants for DB queries.
 * @param {Date|string|number|null} date 
 * @returns {{ startOfDay: Date, endOfDay: Date }}
 */
export function getISTDateRange(date = null) {
    // Get current time or provided date
    const baseDate = date ? new Date(date) : new Date();
    
    // Get IST date components using Intl
    const istParts = new Intl.DateTimeFormat('en-US', {
        timeZone: 'Asia/Kolkata',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false
    }).formatToParts(baseDate);
    
    const getPart = (type) => parseInt(istParts.find(p => p.type === type)?.value || '0', 10);
    
    const year = getPart('year');
    const month = getPart('month') - 1; // JS months are 0-indexed
    const day = getPart('day');
    
    // Create IST midnight (00:00:00) and end of day (23:59:59.999)
    // Then convert to UTC by subtracting IST offset
    const startIST = new Date(year, month, day, 0, 0, 0, 0);
    const endIST = new Date(year, month, day, 23, 59, 59, 999);
    
    // Convert IST times to UTC for database queries
    const startUTC = new Date(startIST.getTime() - IST_OFFSET_MS);
    const endUTC = new Date(endIST.getTime() - IST_OFFSET_MS);

    console.log('📅 IST Date range calculated:', {
        baseDate: baseDate.toISOString(),
        istDate: `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`,
        startOfDayUTC: startUTC.toISOString(),
        endOfDayUTC: endUTC.toISOString()
    });

    return {
        startOfDay: startUTC,
        endOfDay: endUTC
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

    console.log('⏱️ Work hours calculation:', {
        startTime: s.toISOString(),
        endTime: e.toISOString(),
        diffMs,
        hours: Math.max(0, Math.round(hours * 100) / 100)
    });

    return Math.max(0, Math.round(hours * 100) / 100);
}

/**
 * Calculate current active work duration for attendance
 * @param {Date|string|number} punchInTime - UTC instant from database
 * @returns {number} - hours worked
 */
export function getCurrentWorkDurationIST(punchInTime) {
    if (!punchInTime) return 0;

    const punchIn = new Date(punchInTime);
    const now = new Date();

    console.log('📊 Current work duration calculation:', {
        punchInTimeUTC: punchIn.toISOString(),
        currentTimeUTC: now.toISOString(),
        punchInIST: formatISTTime(punchIn, 'datetime'),
        currentIST: formatISTTime(now, 'datetime')
    });

    return calculateWorkHoursIST(punchIn, now);
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
        offsetMs: IST_OFFSET_MS
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
