// Validation middleware for request data

export const validateAccountCreate = (req, res, next) => {
  const { personName, contactNumber } = req.body;
  
  const errors = [];
  
  if (!personName || personName.trim() === '') {
    errors.push('Person name is required');
  }
  
  if (!contactNumber || contactNumber.trim() === '') {
    errors.push('Contact number is required');
  } else if (!/^[0-9]{10}$/.test(contactNumber)) {
    errors.push('Contact number must be 10 digits');
  }
  
  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors
    });
  }
  
  next();
};

export const validateLocationCreate = (req, res, next) => {
  const { name } = req.body;
  
  if (!name || name.trim() === '') {
    return res.status(400).json({
      success: false,
      message: 'Name is required'
    });
  }
  
  next();
};

export const validatePagination = (req, res, next) => {
  const { page, limit } = req.query;
  
  if (page && (isNaN(page) || parseInt(page) < 1)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid page number'
    });
  }
  
  if (limit && (isNaN(limit) || parseInt(limit) < 1 || parseInt(limit) > 100)) {
    return res.status(400).json({
      success: false,
      message: 'Limit must be between 1 and 100'
    });
  }
  
  next();
};
