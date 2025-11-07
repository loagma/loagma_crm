export const roleGuard = (allowedRoles) => {
  return (req, res, next) => {
    const userRole = req.user.role; // e.g., "NSM - National Sales Manager"
    const roleCode = userRole?.split(' ')[0]; // e.g., "NSM"

    if (!allowedRoles.includes(roleCode))
      return res.status(403).json({ success: false, message: 'Access denied' });

    next();
  };
};
