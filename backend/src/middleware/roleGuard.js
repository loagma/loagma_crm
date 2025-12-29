export const roleGuard = (allowedRoles) => {
  return (req, res, next) => {
    const userRole = req.user.role; // e.g., "NSM - National Sales Manager" or "Admin"
    const roleCode = userRole?.split(' ')[0]?.toUpperCase(); // e.g., "NSM" or "ADMIN"

    // Convert allowed roles to uppercase for case-insensitive comparison
    const allowedRolesUpper = allowedRoles.map(r => r.toUpperCase());

    if (!roleCode || !allowedRolesUpper.includes(roleCode)) {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }

    next();
  };
};
