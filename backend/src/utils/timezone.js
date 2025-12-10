/**
 * Timezone utility for Indian Standard Time (IST) handling
 * IST is UTC+5:30
 */

// IST offset in milliseconds (5 hours 30 minutes)
const IST_OFFSET = 5.5 * 60 * 60 * 1000;

/**
 * Get current IST time
 * @returns {Date} Current time in IST
 */
export function getCurrentISTTime() {
    const now = new Date();
    const utc = now.getTime() + (now.getTimezoneOffset() * 60000);
    const ist = new Date(utc + IST_OFFSET);
    return ist;
}

/**
 * Convert UTC date to IST
 * @param {Date} utcDate - UTC date
 * @returns {Date} IST date
 */
export function convertUTCToIST(utcDate) {
    if (!utcDate) return null;
    const utc = new Date(utcDate).getTime();
    return new Date(utc + IST_OFFSET);
}

/**
 * Convert IST date to UTC
 * @param {Date} istDate - IST date
 * @returns {Date} UTC date
 */
export function convertISTToUTC(istDate) {
    if (!istDate) return null;
    const ist = new Date(istDate).getTime();
    return new Date(ist - IST_OFFSET);
}

/**
 * Get IST date range for a specific date (start and end of day in IST)
 * @param {Date} date - Date in IST (optional, defaults to today)
 * @returns {Object} { startOfDay, endOfDay } in UTC for database queries
 */
export function getISTDateRange(date = null) {
    const targetDate = date ? new Date(date) : getCurrentISTTime();
    
    // Start of day in IST (00:00:00)
    const startOfDayIST = new Date(targetDate);
    startOfDayIST.setHours(0, 0, 0, 0);
    
    // End of day in IST (23:59:59.999)
    const endOfDayIST = new Date(targetDate);
    endOfDayIST.setHours(23, 59, 59, 999);
    
    // Convert to UTC for database storage
    return {
        startOfDay: convertISTToUTC(startOfDayIST),
        endOfDay: convertISTToUTC(endOfDayIST)
    };
}

/**
 * Format IST time for display
 * @param {Date} date - Date to format
 * @param {string} format - Format type ('time', 'date', 'datetime')
 * @returns {string} Formatted string
 */
export function formatISTTime(date, format = 'datetime') {
    if (!date) return null;
    
    const istDate = convertUTCToIST(date);
    
    const options = {
        timeZone: 'Asia/Kolkata',
        hour12: true
    };
    
    switch (format) {
        case 'time':
            return istDate.toLocaleTimeString('en-IN', {
                ...options,
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit'
            });
        case 'date':
            return istDate.toLocaleDateString('en-IN', {
                ...options,
                year: 'numeric',
                month: '2-digit',
                day: '2-digit'
            });
        case 'datetime':
            return istDate.toLocaleString('en-IN', {
                ...options,
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit'
            });
        default:
            return istDate.toISOString();
    }
}

/**
 * Get IST timestamp string
 * @param {Date} date - Date (optional, defaults to now)
 * @returns {string} IST timestamp in ISO format
 */
export function getISTTimestamp(date = null) {
    const istTime = date ? convertUTCToIST(date) : getCurrentISTTime();
    return istTime.toISOString();
}

/**
 * Calculate work hours between two IST times
 * @param {Date} startTime - Start time in UTC (from database)
 * @param {Date} endTime - End time in UTC (from database)
 * @returns {number} Work hours
 */
export function calculateWorkHoursIST(startTime, endTime) {
    if (!startTime || !endTime) return 0;
    
    const start = new Date(startTime);
    const end = new Date(endTime);
    
    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
        console.error('Invalid date provided for work hours calculation');
        return 0;
    }
    
    const diffMs = end.getTime() - start.getTime();
    const hours = diffMs / (1000 * 60 * 60);
    
    return Math.max(0, Math.round(hours * 100) / 100);
}

/**
 * Get current work duration for active attendance
 * @param {Date} punchInTime - Punch in time in UTC (from database)
 * @returns {number} Current work hours
 */
export function getCurrentWorkDurationIST(punchInTime) {
    if (!punchInTime) return 0;
    
    const now = getCurrentISTTime();
    const nowUTC = convertISTToUTC(now);
    
    return calculateWorkHoursIST(punchInTime, nowUTC);
}

/**
 * Validate if a time is within IST business hours
 * @param {Date} time - Time to validate
 * @param {number} startHour - Business start hour (default: 9)
 * @param {number} endHour - Business end hour (default: 18)
 * @returns {boolean} True if within business hours
 */
export function isWithinBusinessHours(time, startHour = 9, endHour = 18) {
    const istTime = convertUTCToIST(time);
    const hour = istTime.getHours();
    return hour >= startHour && hour < endHour;
}

/**
 * Get IST timezone info
 * @returns {Object} Timezone information
 */
export function getISTTimezoneInfo() {
    return {
        name: 'India Standard Time',
        abbreviation: 'IST',
        offset: '+05:30',
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